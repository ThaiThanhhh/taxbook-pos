import { Injectable, NotFoundException } from '@nestjs/common';
import { Database } from '../../common/database';
import { invalid } from '../../common/http';
import { date, hash, uuid } from '../ledger/helpers';
import { validateHousehold } from '../ledger/ledger-summary.service';

export function snapshotFromRow(row: Record<string, any>) {
  return { id: row.id as string, schema_version: row.schema_version as number,
    household_id: row.household_id as string, period_id: row.period_id as string,
    from: row.start_date as string, to: row.end_date as string, source: 'POSTED_LEDGER' as const,
    status: 'DRAFT' as const, official: false as const, tax_result: null,
    totals: { revenue_vnd: Number(row.revenue_vnd), expense_vnd: Number(row.expense_vnd), entry_count: Number(row.entry_count) },
    param_set_id: row.param_set_id, param_version: row.param_version, param_status: row.param_status,
    param_fingerprint: row.param_fingerprint, source_revision: row.source_revision as string,
    digest: row.digest as string, captured_at: new Date(row.created_at).toISOString() };
}
function withFreshness(row: Record<string, any>) {
  const reasons: string[] = [];
  if (row.current_revision !== row.source_revision) reasons.push('LEDGER_REVISION_CHANGED');
  if (row.current_status !== 'DRAFT') reasons.push('PERIOD_NOT_DRAFT');
  if (row.current_from !== row.start_date || row.current_to !== row.end_date) reasons.push('PERIOD_RANGE_CHANGED');
  if (row.current_param_id !== row.param_set_id || row.current_version !== row.param_version ||
      row.current_param_status !== row.param_status ||
      (row.current_param_id ? hash(row.current_payload) : null) !== row.param_fingerprint) reasons.push('PARAM_CONTEXT_CHANGED');
  return { ...snapshotFromRow(row), stale: reasons.length > 0, stale_reasons: reasons, current_source_revision: row.current_revision as string };
}
export interface SnapshotPage { period_id?: string; limit?: number; cursor?: string }

@Injectable()
export class DraftSnapshotReader {
  constructor(private readonly database: Database) {}

  // One statement snapshot: ledger revision and all period/param contexts are read together.
  private async rows(household: string, period: string | null, after: [string,string] | null, ids: string[] | null, limit: number) {
    return (await this.database.query(`SELECT s.*,s.start_date::text,s.end_date::text,s.source_revision::text,
      to_char(s.created_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS cursor_time,
      l.ledger_revision::text AS current_revision,p.start_date::text AS current_from,p.end_date::text AS current_to,
      p.status AS current_status,p.param_set_id AS current_param_id,t.version AS current_version,
      t.status AS current_param_status,t.payload AS current_payload
      FROM tax_draft_snapshot s JOIN ledger_household_lock l ON l.household_id=s.household_id
      JOIN tax_period p ON p.household_id=s.household_id AND p.id=s.period_id
      LEFT JOIN tax_param_set t ON t.id=p.param_set_id
      WHERE s.household_id=$1 AND ($2::uuid IS NULL OR s.period_id=$2)
      AND ($3::timestamptz IS NULL OR (s.created_at,s.id)>($3::timestamptz,$4::uuid))
      AND ($5::uuid[] IS NULL OR s.id=ANY($5::uuid[])) ORDER BY s.created_at,s.id LIMIT $6`,
    [household,period,after?.[0] ?? null,after?.[1] ?? null,ids,limit])).rows;
  }

  async list(household: string, options: SnapshotPage = {}) {
    validateHousehold(household);
    if (options.period_id !== undefined) uuid(options.period_id,'period_id');
    const limit = options.limit ?? 50;
    if (!Number.isInteger(limit) || limit<1 || limit>200) invalid('limit','Expected 1–200');
    const scope = hash({ household, period: options.period_id ?? null });
    let after: [string,string] | null = null;
    if (options.cursor !== undefined) {
      try {
        if (typeof options.cursor !== 'string' || options.cursor.length>2000) throw new Error();
        const c = JSON.parse(Buffer.from(options.cursor,'base64url').toString());
        if (c.scope !== scope || !/^\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d\.\d{6}Z$/.test(c.time)) throw new Error();
        date(c.time.slice(0,10),'cursor'); uuid(c.id,'cursor'); after=[c.time,c.id];
      } catch { invalid('cursor','Invalid cursor or different household/period'); }
    }
    const rows = await this.rows(household,options.period_id ?? null,after,null,limit+1);
    const page = rows.slice(0,limit); const last = page.at(-1);
    return { items: page.map(withFreshness), next_cursor: rows.length>limit ?
      Buffer.from(JSON.stringify({ scope,time:last!.cursor_time,id:last!.id })).toString('base64url') : null };
  }

  async freshness(household: string, ids: string[]) {
    validateHousehold(household);
    if (!Array.isArray(ids) || ids.length>200) invalid('ids','Expected at most 200 snapshot IDs');
    for (const id of ids) uuid(id,'snapshot_id');
    if (!ids.length) return { items: [] };
    // Foreign/unknown IDs are both omitted; do not disclose existence in other households.
    return { items: (await this.rows(household,null,null,[...new Set(ids)],200)).map(withFreshness) };
  }
  async read(household: string, id: string) {
    const result = await this.freshness(household,[id]);
    if (!result.items.length) throw new NotFoundException('Draft snapshot not found');
    return result.items[0];
  }
}
