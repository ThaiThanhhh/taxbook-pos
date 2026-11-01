import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Database } from '../../common/database';
import { hash, lockHousehold, uuid } from '../ledger/helpers';
import { LedgerSummaryService, validateHousehold, validateRange } from '../ledger/ledger-summary.service';

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

  /** Internal draft input preparation, no calculation/confirmation or persisted financial write.
   * All writers must take the same household lock; output is stale after transaction ends.
   */
  async prepareSnapshot(household: string, periodId: string) {
    validateHousehold(household);
    uuid(periodId, 'period_id');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      const result = await client.query(`SELECT p.id,p.start_date::text,p.end_date::text,p.status,
        p.param_set_id,t.version AS param_version,t.status AS param_status
        FROM tax_period p LEFT JOIN tax_param_set t ON t.id=p.param_set_id
        WHERE p.household_id=$1 AND p.id=$2 FOR UPDATE OF p`, [household, periodId]);
      if (!result.rows.length) throw new NotFoundException('Tax period not found');
      const period = result.rows[0];
      if (period.status !== 'DRAFT') throw new ConflictException({ code: 'PERIOD_LOCKED', message: 'Cannot rebuild inputs for confirmed period' });
      const range = { from: period.start_date as string, to: period.end_date as string };
      validateRange(household, range);
      const totals = await this.ledger.range(household, range, client);
      const snapshot = { schema_version: 1, household_id: household, period_id: periodId, ...range,
        source: 'POSTED_LEDGER' as const, status: 'DRAFT' as const, totals,
        param_set_id: period.param_set_id ?? null, param_version: period.param_version ?? null,
        param_status: period.param_status ?? null, tax_result: null, official: false as const };
      return { ...snapshot, digest: hash(snapshot), captured_at: new Date().toISOString() };
    });
  }
}
