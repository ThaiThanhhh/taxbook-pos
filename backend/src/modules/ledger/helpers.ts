import { createHash } from 'node:crypto';
import { ConflictException } from '@nestjs/common';
import { isUUID } from 'class-validator';
import { SqlClient } from '../../common/database';
import { invalid } from '../../common/http';

export function uuid(value: string, field = 'id') {
  if (!isUUID(value)) invalid(field, 'Must be a UUID');
  return value;
}
export function date(value: string, field = 'date') {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || value.startsWith('0000') || !Number.isFinite(Date.parse(value)) ||
      new Date(value).toISOString().slice(0, 10) !== value) invalid(field, 'Must be a real YYYY-MM-DD date');
  return value;
}
export function money(value: unknown, field = 'amount_vnd', signed = false) {
  if (typeof value !== 'number' || !Number.isSafeInteger(value) || (!signed && value < 0)) {
    invalid(field, 'Must be a safe integer VND amount');
  }
  return value;
}
export function hash(value: unknown): string {
  const stable = (item: any): any => Array.isArray(item) ? item.map(stable) :
    item && typeof item === 'object' ? Object.fromEntries(Object.keys(item).sort().map(key => [key, stable(item[key])])) : item;
  return createHash('sha256').update(JSON.stringify(stable(value))).digest('hex');
}
export async function lockHousehold(client: SqlClient, household: string) {
  await client.query('INSERT INTO ledger_household_lock VALUES ($1) ON CONFLICT DO NOTHING', [household]);
  await client.query('SELECT household_id FROM ledger_household_lock WHERE household_id=$1 FOR UPDATE', [household]);
}
export async function assertOpen(client: SqlClient, household: string, day: string) {
  const result = await client.query("SELECT id FROM tax_period WHERE household_id=$1 AND status='CONFIRMED' AND $2::date BETWEEN start_date AND end_date", [household, day]);
  if (result.rows.length) throw new ConflictException({ code: 'PERIOD_LOCKED', message: 'Tax period is locked' });
}
export async function idempotent<T>(client: SqlClient, household: string, operation: string, key: string, input: unknown, work: () => Promise<T>): Promise<T> {
  uuid(key, 'Idempotency-Key');
  const fingerprint = hash(input);
  const previous = await client.query('SELECT fingerprint, response FROM ledger_idempotency WHERE household_id=$1 AND operation=$2 AND key=$3', [household, operation, key]);
  if (previous.rows.length) {
    if (previous.rows[0].fingerprint !== fingerprint) throw new ConflictException('Idempotency key reused with different input');
    return previous.rows[0].response;
  }
  const response = await work();
  await client.query('INSERT INTO ledger_idempotency VALUES ($1,$2,$3,$4,$5::jsonb)', [household, operation, key, fingerprint, JSON.stringify(response)]);
  return response;
}
export function cursor(value: string | undefined, scope: unknown): [string, string] | undefined {
  if (!value) return;
  try {
    const parsed = JSON.parse(Buffer.from(value, 'base64url').toString());
    if (parsed.scope !== hash(scope)) throw new Error();
    date(parsed.date, 'cursor'); uuid(parsed.id, 'cursor');
    return [parsed.date, parsed.id];
  } catch { invalid('cursor', 'Invalid cursor or different filters'); }
}
export function page<T extends { id: string }>(rows: T[], limit: number, dayField: keyof T, scope: unknown) {
  const items = rows.slice(0, limit);
  const last = items.at(-1);
  return { items, next_cursor: rows.length > limit && last ? Buffer.from(JSON.stringify({
    date: last[dayField], id: last.id, scope: hash(scope),
  })).toString('base64url') : null };
}
