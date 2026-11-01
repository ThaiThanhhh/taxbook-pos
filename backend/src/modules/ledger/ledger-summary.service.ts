import { Injectable } from '@nestjs/common';
import { Database, SqlClient } from '../../common/database';
import { invalid } from '../../common/http';
import { date, hash, money } from './helpers';

export interface LedgerRange { from: string; to: string }
export interface LedgerTotals { revenue_vnd: number; expense_vnd: number; entry_count: number }
export function validateHousehold(household: string) {
  if (typeof household !== 'string' || !household.trim() || household.length > 200) invalid('household', 'Expected household identifier');
}
export function validateRange(household: string, range: LedgerRange) {
  validateHousehold(household);
  if (!range || typeof range !== 'object') invalid('range', 'Expected from/to dates');
  date(range.from, 'from'); date(range.to, 'to');
  if (range.from > range.to) invalid('to', 'Must be on or after from');
}
function totals(row: Record<string, string>): LedgerTotals {
  // PostgreSQL SUM(bigint) is numeric. Read text and check exact range before JSON conversion.
  const exact = (value: string) => {
    const amount = BigInt(value);
    if (amount > BigInt(Number.MAX_SAFE_INTEGER) || amount < BigInt(Number.MIN_SAFE_INTEGER)) invalid('totals', 'Aggregate exceeds safe integer VND range');
    return money(Number(amount), 'totals', true);
  };
  return { revenue_vnd: exact(row.revenue_vnd), expense_vnd: exact(row.expense_vnd), entry_count: exact(row.entry_count) };
}
const sums = `COALESCE(SUM(amount_vnd) FILTER (WHERE type='REVENUE'),0)::text AS revenue_vnd,
  COALESCE(SUM(amount_vnd) FILTER (WHERE type='EXPENSE'),0)::text AS expense_vnd, count(*)::text AS entry_count`;

/** Posted ledger amounts only: not taxable bases, accounting profit or payment cashflow. */
@Injectable()
export class LedgerSummaryService {
  constructor(private readonly database: Database) {}

  async range(household: string, range: LedgerRange, client: SqlClient = this.database): Promise<LedgerTotals> {
    validateRange(household, range);
    const result = await client.query(`SELECT ${sums} FROM ledger_entry
      WHERE household_id=$1 AND entry_date BETWEEN $2::date AND $3::date AND type IN ('REVENUE','EXPENSE')`, [household, range.from, range.to]);
    return totals(result.rows[0]);
  }

  async buckets(household: string, range: LedgerRange, options: { by: 'DAY' | 'MONTH'; limit?: number; cursor?: string }) {
    validateRange(household, range);
    if (!['DAY','MONTH'].includes(options.by)) invalid('by', 'Expected DAY or MONTH');
    const limit = options.limit ?? 50;
    if (!Number.isInteger(limit) || limit < 1 || limit > 200) invalid('limit', 'Expected 1–200');
    const scope = hash({ household, ...range, by: options.by });
    let after: string | null = null;
    if (options.cursor !== undefined) {
      try {
        if (typeof options.cursor !== 'string' || options.cursor.length > 2000) throw new Error();
        const parsed = JSON.parse(Buffer.from(options.cursor, 'base64url').toString());
        if (parsed.scope !== scope || typeof parsed.bucket !== 'string') throw new Error();
        date(options.by === 'MONTH' ? `${parsed.bucket}-01` : parsed.bucket, 'cursor');
        after = parsed.bucket;
      } catch { invalid('cursor', 'Invalid cursor or different filters'); }
    }
    const bucket = options.by === 'DAY' ? 'entry_date::text' : "to_char(entry_date,'YYYY-MM')";
    const result = await this.database.query(`SELECT ${bucket} AS bucket, ${sums} FROM ledger_entry
      WHERE household_id=$1 AND entry_date BETWEEN $2::date AND $3::date AND type IN ('REVENUE','EXPENSE')
      GROUP BY ${bucket} HAVING ($4::text IS NULL OR ${bucket}>$4) ORDER BY bucket LIMIT $5`,
    [household, range.from, range.to, after, limit + 1]);
    const items = result.rows.slice(0, limit).map(row => ({ bucket: row.bucket as string, ...totals(row) }));
    return { items, next_cursor: result.rows.length > limit ? Buffer.from(JSON.stringify({ scope, bucket: items.at(-1)!.bucket })).toString('base64url') : null };
  }
}
