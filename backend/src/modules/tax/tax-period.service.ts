import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Database } from '../../common/database';
import { hash, lockHousehold, uuid } from '../ledger/helpers';
import { LedgerSummaryService, validateHousehold, validateRange } from '../ledger/ledger-summary.service';
import { randomUUID } from 'node:crypto';

function snapshotFromRow(row: Record<string, any>) {
  return { id: row.id as string, schema_version: row.schema_version as number,
    household_id: row.household_id as string, period_id: row.period_id as string,
    from: row.start_date as string, to: row.end_date as string, source: 'POSTED_LEDGER' as const,
    status: 'DRAFT' as const, official: false as const, tax_result: null,
    totals: { revenue_vnd: Number(row.revenue_vnd), expense_vnd: Number(row.expense_vnd), entry_count: Number(row.entry_count) },
    param_set_id: row.param_set_id, param_version: row.param_version, param_status: row.param_status,
    param_fingerprint: row.param_fingerprint, source_revision: row.source_revision as string,
    digest: row.digest as string, captured_at: new Date(row.created_at).toISOString() };
}
const snapshotColumns = '*,start_date::text,end_date::text,source_revision::text';

@Injectable()
export class TaxPeriodService {
  constructor(private readonly database: Database, private readonly ledger: LedgerSummaryService) {}

  async list(household: string) {
    validateHousehold(household);
    const result = await this.database.query(`SELECT id,label,start_date::text,end_date::text,status,
      revenue_vnd::float8,vat_vnd::float8,pit_vnd::float8,method,param_set_id
      FROM tax_period WHERE household_id=$1 ORDER BY start_date,id`, [household]);
    return { items: result.rows.map(row => Object.fromEntries(Object.entries(row).filter(([,value]) => value !== null))) };
  }

  /** Persist internal draft inputs only, never a financial calculation or period confirmation.
   * The revision trigger tracks any committed ledger mutation, even equal-total edits.
   */
  async prepareSnapshot(household: string, periodId: string) {
    validateHousehold(household);
    uuid(periodId, 'period_id');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      const result = await client.query(`SELECT p.id,p.start_date::text,p.end_date::text,p.status,
        p.param_set_id,t.version AS param_version,t.status AS param_status,t.payload AS param_payload
        FROM tax_period p LEFT JOIN tax_param_set t ON t.id=p.param_set_id
        WHERE p.household_id=$1 AND p.id=$2 FOR UPDATE OF p`, [household, periodId]);
      if (!result.rows.length) throw new NotFoundException('Tax period not found');
      const period = result.rows[0];
      if (period.status !== 'DRAFT') throw new ConflictException({ code: 'PERIOD_LOCKED', message: 'Cannot rebuild inputs for confirmed period' });
      const range = { from: period.start_date as string, to: period.end_date as string };
      validateRange(household, range);
      const totals = await this.ledger.range(household, range, client);
      const revision = (await client.query('SELECT ledger_revision::text AS revision FROM ledger_household_lock WHERE household_id=$1', [household])).rows[0].revision as string;
      const snapshot = { schema_version: 1, household_id: household, period_id: periodId, ...range,
        source: 'POSTED_LEDGER' as const, status: 'DRAFT' as const, totals,
        param_set_id: period.param_set_id ?? null, param_version: period.param_version ?? null,
        param_status: period.param_status ?? null, param_fingerprint: period.param_set_id ? hash(period.param_payload) : null,
        source_revision: revision, tax_result: null, official: false as const };
      const saved = await client.query(`INSERT INTO tax_draft_snapshot
        (id,household_id,period_id,start_date,end_date,revenue_vnd,expense_vnd,entry_count,schema_version,
         param_set_id,param_version,param_status,param_fingerprint,source_revision,digest)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,1,$9,$10,$11,$12,$13,$14)
        ON CONFLICT (household_id,period_id,source_revision,digest) DO NOTHING RETURNING ${snapshotColumns}`,
      [randomUUID(), household, periodId, range.from, range.to, totals.revenue_vnd, totals.expense_vnd, totals.entry_count,
        snapshot.param_set_id, snapshot.param_version, snapshot.param_status, snapshot.param_fingerprint, revision, hash(snapshot)]);
      const row = saved.rows[0] ?? (await client.query(`SELECT ${snapshotColumns} FROM tax_draft_snapshot
        WHERE household_id=$1 AND period_id=$2 AND source_revision=$3 AND digest=$4`, [household,periodId,revision,hash(snapshot)])).rows[0];
      return snapshotFromRow(row);
    });
  }

  async readSnapshot(household: string, snapshotId: string) {
    validateHousehold(household); uuid(snapshotId, 'snapshot_id');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      const result = await client.query(`SELECT ${snapshotColumns} FROM tax_draft_snapshot WHERE household_id=$1 AND id=$2`, [household,snapshotId]);
      if (!result.rows.length) throw new NotFoundException('Draft snapshot not found');
      const row = result.rows[0];
      const current = (await client.query(`SELECT p.start_date::text,p.end_date::text,p.status,p.param_set_id,
        t.version,t.status AS param_status,t.payload,l.ledger_revision::text AS revision
        FROM tax_period p JOIN ledger_household_lock l ON l.household_id=p.household_id
        LEFT JOIN tax_param_set t ON t.id=p.param_set_id WHERE p.household_id=$1 AND p.id=$2 FOR UPDATE OF p`,
      [household,row.period_id])).rows[0];
      const stale = current.revision !== row.source_revision || current.status !== 'DRAFT' ||
        current.start_date !== row.start_date || current.end_date !== row.end_date ||
        current.param_set_id !== row.param_set_id || current.version !== row.param_version ||
        current.param_status !== row.param_status || (current.param_set_id ? hash(current.payload) : null) !== row.param_fingerprint;
      return { ...snapshotFromRow(row), stale, current_source_revision: current.revision as string };
    });
  }
}
