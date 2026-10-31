import 'reflect-metadata';
import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { PGlite } from '@electric-sql/pglite';
import { INestApplication } from '@nestjs/common';
import { sign } from 'jsonwebtoken';
import { QueryResultRow } from 'pg';
import { createApp } from '../../app';
import { Database, SqlClient } from '../../common/database';
import { LedgerService } from './ledger.service';
import { parseBankCsv } from './bank.service';

// PGlite executes PostgreSQL SQL, constraints, and transactions in-process.
// This is not a pg Pool/network test; run the documented smoke check against PostgreSQL too.
class TestDatabase extends Database {
  readonly engine = new PGlite();
  override async query<T extends QueryResultRow = QueryResultRow>(sql: string, values?: unknown[]) {
    const result = await this.engine.query<T>(sql, values);
    return { rows: result.rows, command: '', rowCount: result.rows.length, oid: 0, fields: [] };
  }
  override async transaction<T>(work: (client: SqlClient) => Promise<T>): Promise<T> {
    return this.engine.transaction(client => work({ query: (sql, values) => client.query(sql, values) }));
  }
  override async onModuleDestroy() { await this.engine.close(); await super.onModuleDestroy(); }
}
let app: INestApplication;
let database: Database;
let base: string;
const secret = 'integration-test-only-not-a-real-secret-123456';
function token(household = 'house-a', role = 'OWNER') {
  return sign({ household_id: household, role }, secret, { algorithm: 'HS256', issuer: 'taxbook-pos', audience: 'taxbook-pos-api', expiresIn: '5m' });
}
async function request(path: string, options: { method?: string; body?: unknown; household?: string; role?: string; key?: string; auth?: string | null } = {}) {
  const headers: Record<string, string> = {};
  const auth = options.auth === undefined ? token(options.household, options.role) : options.auth;
  if (auth) headers.authorization = `Bearer ${auth}`;
  if (options.key) headers['Idempotency-Key'] = options.key;
  if (options.body) headers['content-type'] = 'application/json';
  const response = await fetch(`${base}${path}`, { method: options.method ?? 'GET', headers,
    body: options.body ? JSON.stringify(options.body) : undefined });
  return { status: response.status, body: await response.json() as any };
}
const expense = { date: '2026-10-30', amount_vnd: 125000, category: 'supplies' };

before(async () => {
  process.env.JWT_SECRET = secret;
  process.env.JWT_ISSUER = 'taxbook-pos';
  process.env.JWT_AUDIENCE = 'taxbook-pos-api';
  process.env.TAX_CONFIG_DIR = resolve('../config/tax');
  if (process.env.TEST_DATABASE_URL) {
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    database = new Database();
    const tables = await database.query("SELECT tablename FROM pg_tables WHERE schemaname='public'");
    if (tables.rows.length) throw new Error('TEST_DATABASE_URL must point to a disposable empty database');
  } else { database = new TestDatabase(); }
  for (const module of ['ledger', 'tax']) {
    const sql = await readFile(resolve('src/modules', module, 'schema.sql'), 'utf8');
    if (database instanceof TestDatabase) await database.engine.exec(sql);
    else await database.query(sql);
  }
  app = await createApp(database);
  await app.listen(0, '127.0.0.1');
  base = `${await app.getUrl()}/api/v1`;
});
after(async () => { if (app) await app.close(); else if (database) await database.onModuleDestroy(); });

test('requires a signed expiring JWT and restricts STAFF', async () => {
  assert.equal((await request('/ledger', { auth: null })).status, 401);
  assert.equal((await request('/ledger', { auth: 'test' })).status, 401);
  assert.equal((await request('/ledger', { role: 'STAFF' })).status, 403);
  const expired = sign({ household_id: 'house-a', role: 'OWNER' }, secret, { issuer: 'taxbook-pos', audience: 'taxbook-pos-api', expiresIn: -1 });
  assert.equal((await request('/ledger', { auth: expired })).status, 401);
});

test('manual expense posts once; idempotent retries return the same response', async () => {
  const key = randomUUID();
  const first = await request('/expenses', { method: 'POST', key, body: expense });
  assert.equal(first.status, 201);
  assert.equal(first.body.confirmed, true);
  const retry = await request('/expenses', { method: 'POST', key, body: expense });
  assert.deepEqual(retry.body, first.body);
  const changed = await request('/expenses', { method: 'POST', key, body: { ...expense, amount_vnd: 1 } });
  assert.equal(changed.status, 409);
  const ledger = await request('/ledger');
  assert.equal(ledger.body.items.filter((row: any) => row.ref_id === first.body.id).length, 1);
  assert.equal(ledger.body.items[0].entry_date, expense.date);
  assert.equal(ledger.body.items[0].amount_vnd, expense.amount_vnd);
});

test('OCR draft stays outside ledger until confirmation; repeated confirmation is safe', async () => {
  const created = await request('/expenses', { method: 'POST', key: randomUUID(), body: { ...expense, source: 'OCR' } });
  assert.equal(created.status, 201);
  assert.equal(created.body.confirmed, false);
  const id = created.body.id;
  assert.equal((await request('/ledger')).body.items.some((row: any) => row.ref_id === id), false);
  assert.equal((await request(`/expenses/${id}/confirm`, { household: 'house-b', method: 'POST', key: randomUUID() })).status, 404);
  const confirmed = await request(`/expenses/${id}/confirm`, { method: 'POST', key: randomUUID() });
  assert.equal(confirmed.status, 200);
  assert.equal(confirmed.body.confirmed, true);
  await request(`/expenses/${id}/confirm`, { method: 'POST', key: randomUUID() });
  assert.equal((await request('/ledger')).body.items.filter((row: any) => row.ref_id === id).length, 1);
});

test('rejects unsafe money, impossible dates, unknown fields and missing idempotency keys', async () => {
  for (const change of [{ amount_vnd: -1 }, { amount_vnd: 1.5 }, { amount_vnd: Number.MAX_SAFE_INTEGER + 1 }, { date: '2026-02-30' }, { household_id: 'house-b' }]) {
    const response = await request('/expenses', { method: 'POST', key: randomUUID(), body: { ...expense, ...change } });
    assert.equal(response.status, 422);
    assert.equal(response.body.error.code, 'VALIDATION_FAILED');
    assert.ok(response.body.error.trace_id);
  }
  assert.equal((await request('/expenses', { method: 'POST', body: expense })).status, 422);
  assert.equal((await request('/ledger?from=2026-10-31&to=2026-10-01')).status, 422);
  assert.equal((await request('/ledger?limit=201')).status, 422);
});

test('stable cursor pagination is scoped to household and filters', async () => {
  const first = await request('/ledger?limit=1');
  assert.equal(first.body.items.length, 1);
  assert.ok(first.body.next_cursor);
  const second = await request(`/ledger?limit=1&cursor=${first.body.next_cursor}`);
  assert.equal(second.status, 200);
  assert.notEqual(first.body.items[0].id, second.body.items[0].id);
  assert.deepEqual((await request('/ledger', { household: 'house-b' })).body.items, []);
  assert.equal((await request(`/ledger?cursor=${first.body.next_cursor}`, { household: 'house-b' })).status, 422);
});

test('accepted sale integration records original sale date and rejects changed retries', async () => {
  const service = app.get(LedgerService);
  const sale = { sale_id: 'sale-01', entry_date: '2026-10-20', amount_vnd: 90000, sector_code: 'GOODS_DISTRIBUTION',
    payments: [{ method: 'QR_TRANSFER' as const, amount_vnd: 90000 }] };
  assert.deepEqual(await service.recordSale('house-bank', sale), { duplicate: false });
  assert.deepEqual(await service.recordSale('house-bank', sale), { duplicate: true });
  await assert.rejects(() => service.recordSale('house-bank', { ...sale, sector_code: 'SERVICE' }));
  const rows = (await request('/ledger', { household: 'house-bank' })).body.items;
  assert.equal(rows.filter((r: any) => r.type === 'REVENUE').length, 1);
  assert.ok(rows.every((r: any) => r.entry_date === '2026-10-20'));
});

test('CSV parser preserves identical rows, handles BOM and quotes, rejects a bad row atomically', async () => {
  const rows = parseBankCsv('\uFEFFtxn_date,amount_vnd,description\r\n2026-10-20,90000,"paid, thanks"\r\n2026-10-20,90000,"paid, thanks"');
  assert.equal(rows.length, 2);
  assert.equal(rows[0].description, 'paid, thanks');
  assert.throws(() => parseBankCsv('txn_date,amount_vnd,description\n2026-02-30,90000,x'));
  assert.throws(() => parseBankCsv('txn_date,amount_vnd,description\n2026-10-20,1.5,x'));
  assert.throws(() => parseBankCsv('a,b,c\n2026-10-20,90000,x'));
});

test('CSV import retries do not duplicate rows; matching requires user confirmation', async () => {
  const csv = 'txn_date,amount_vnd,description\n2026-10-20,90000,paid\n2026-10-20,90000,paid';
  const upload = async () => {
    const form = new FormData(); form.append('file', new Blob([csv]), 'bank.csv');
    const response = await fetch(`${base}/bank-statements/import`, { method: 'POST', headers: { authorization: `Bearer ${token('house-bank')}` }, body: form });
    assert.equal(response.status, 201);
    return response.json() as Promise<any>;
  };
  assert.deepEqual(await upload(), { imported: 2, auto_matched: 0, unmatched: 2 });
  assert.equal((await upload()).imported, 0);
  const lines = (await request('/bank-statements/matches', { household: 'house-bank' })).body.items;
  assert.equal(lines.length, 2);
  assert.equal(lines[0].status, 'UNMATCHED');
  const input = { action: 'CONFIRM', ledger_id: lines[0].suggested_ledger_id };
  assert.ok(input.ledger_id);
  const matched = await request(`/bank-statements/${lines[0].id}/match`, { method: 'POST', household: 'house-bank', key: randomUUID(), body: input });
  assert.equal(matched.status, 200);
  assert.equal(matched.body.status, 'MATCHED');
  assert.equal((await request(`/bank-statements/${lines[1].id}/match`, { method: 'POST', household: 'house-bank', key: randomUUID(), body: input })).status, 409);
  assert.equal((await request(`/bank-statements/${lines[0].id}/match`, { method: 'POST', household: 'house-b', key: randomUUID(), body: input })).status, 404);
});

test('confirmed tax period prevents new postings and OCR confirmation without partial writes', async () => {
  const created = await request('/expenses', { method: 'POST', key: randomUUID(), body: { ...expense, date: '2026-11-10', source: 'OCR' } });
  const paramId = randomUUID();
  await database.query("INSERT INTO tax_param_set (id,version,effective_from,status,approved_by,payload) VALUES ($1,'test-only','2026-01-01','APPROVED','test-reviewer','{}')", [paramId]);
  await database.query("INSERT INTO tax_period (id,household_id,label,start_date,end_date,status,param_set_id,vat_vnd,pit_vnd) VALUES ($1,'house-a','2026-11','2026-11-01','2026-11-30','CONFIRMED',$2,0,0)", [randomUUID(), paramId]);
  const denied = await request('/expenses', { method: 'POST', key: randomUUID(), body: { ...expense, date: '2026-11-11' } });
  assert.equal(denied.status, 409);
  assert.equal(denied.body.error.code, 'PERIOD_LOCKED');
  const confirm = await request(`/expenses/${created.body.id}/confirm`, { method: 'POST', key: randomUUID() });
  assert.equal(confirm.status, 409);
  const result = await database.query('SELECT confirmed FROM expense WHERE id=$1', [created.body.id]);
  assert.equal(result.rows[0].confirmed, false);
  assert.equal((await request('/ledger?from=2026-11-01&to=2026-11-30')).body.items.length, 0);
});

test('unverified repository tax parameters are not published as official', async () => {
  const response = await request('/tax/params?as_of=2026-10-31');
  assert.equal(response.status, 404);
  assert.match(response.body.error.message, /approved/i);
  assert.equal((await request('/tax/params?as_of=2026-02-30')).status, 422);
});

test('concurrent retries create exactly one expense and posting', async () => {
  const key = randomUUID();
  const results = await Promise.all(Array.from({ length: 8 }, () => request('/expenses', {
    household: 'house-concurrent', method: 'POST', key, body: expense,
  })));
  assert.ok(results.every(result => result.status === 201));
  assert.equal(new Set(results.map(result => result.body.id)).size, 1);
  assert.equal((await request('/ledger', { household: 'house-concurrent' })).body.items.length, 1);
});

test('sale cancellation creates balancing entries exactly once without deleting originals', async () => {
  const service = app.get(LedgerService);
  assert.deepEqual(await service.reverseSale('house-bank', 'sale-01', 'Customer cancelled'), { duplicate: false });
  assert.deepEqual(await service.reverseSale('house-bank', 'sale-01', 'Customer cancelled'), { duplicate: true });
  const rows = (await request('/ledger', { household: 'house-bank' })).body.items;
  const revenues = rows.filter((row: any) => row.type === 'REVENUE');
  assert.equal(revenues.length, 2);
  assert.equal(revenues.reduce((sum: number, row: any) => sum + row.amount_vnd, 0), 0);
  assert.equal(rows.filter((row: any) => row.ref_type === 'SALE').length, 1);
  await assert.rejects(() => service.reverseSale('house-b', 'sale-01', 'Wrong household'));
});
