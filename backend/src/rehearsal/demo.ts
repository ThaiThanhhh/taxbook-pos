import 'reflect-metadata';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { sign } from 'jsonwebtoken';
import { createApp } from '../app';
import { Database } from '../common/database';
import { LedgerService } from '../modules/ledger/ledger.service';
import { LedgerSummaryService } from '../modules/ledger/ledger-summary.service';
import { TaxPeriodService } from '../modules/tax/tax-period.service';
import { lockHousehold } from '../modules/ledger/helpers';
import type { SalePosting } from '../modules/ledger/sales-ledger.contract';
import { migrate, migrationPlan } from './migrations';
import { sandbox } from './sandbox';

async function main() {
  const fixture = await sandbox();
  let database: Database | undefined;
  let reader: Database | undefined;
  let app: Awaited<ReturnType<typeof createApp>> | undefined;
  const steps: string[] = [];
  try {
    const migration = await migrate(fixture.pool, await migrationPlan());
    process.env.DATABASE_URL = fixture.connectionString;
    process.env.JWT_SECRET = randomUUID() + randomUUID();
    process.env.JWT_ISSUER = 'taxbook-pos'; process.env.JWT_AUDIENCE = 'taxbook-pos-api';
    process.env.TAX_CONFIG_DIR = resolve(__dirname, '../../../config/tax');
    database = new Database();
    app = await createApp(database);
    await app.listen(0, '127.0.0.1');
    const base = `${await app.getUrl()}/api/v1`;
    const ledger = app.get(LedgerService);
    const summary = app.get(LedgerSummaryService);
    const tax = app.get(TaxPeriodService);
    const token = (household: string) => sign({ household_id: household, role: 'OWNER' }, process.env.JWT_SECRET!,
      { issuer: 'taxbook-pos', audience: 'taxbook-pos-api', expiresIn: '5m' });
    async function request(path: string, household: string, method: 'GET' | 'POST' = 'GET', body?: unknown, key = randomUUID(), status = 200) {
      const headers = { authorization: `Bearer ${token(household)}`, 'content-type': 'application/json', 'Idempotency-Key': key };
      const response = method === 'GET' ? await fetch(`${base}${path}`, { headers }) :
        await fetch(`${base}${path}`, { method: 'POST', headers, body: body === undefined ? undefined : JSON.stringify(body) });
      const result = await response.json() as any;
      assert.equal(response.status, status, JSON.stringify(result));
      return result;
    }
    // Fake Sales is a test fixture in the owned schema, not Dung's Sales module/schema.
    await database.query(`CREATE TABLE fake_sale(household_id text, id text, status text, PRIMARY KEY(household_id,id))`);
    async function accept(household: string, sale: SalePosting, fail = false) {
      return database!.transaction(async client => {
        await client.query("INSERT INTO fake_sale VALUES ($1,$2,'ACCEPTED') ON CONFLICT DO NOTHING", [household, sale.sale_id]);
        const result = await ledger.recordSale(household, sale, client);
        if (fail) throw new Error('fake Sales caller failed');
        return result;
      });
    }
    const sale: SalePosting = { sale_id: 'demo-sale', entry_date: '2026-10-30', amount_vnd: 150000,
      sector_code: 'SERVICE', payments: [{ method: 'QR_TRANSFER', amount_vnd: 150000 }] };
    assert.deepEqual(await accept('demo-a', sale), { duplicate: false });
    assert.deepEqual(await accept('demo-a', sale), { duplicate: true });
    assert.equal((await database.query("SELECT count(*) FROM ledger_entry WHERE household_id='demo-a' AND ref_type='SALE'")).rows[0].count, '1');
    await assert.rejects(accept('demo-a', { ...sale, sale_id: 'rolled-back' }, true), /fake Sales caller failed/);
    assert.equal((await database.query("SELECT count(*) FROM fake_sale WHERE id='rolled-back'")).rows[0].count, '0');
    assert.equal((await database.query("SELECT count(*) FROM ledger_entry WHERE ref_id='rolled-back'")).rows[0].count, '0');
    steps.push('Fake Sales shared transaction, revenue, duplicate retry and caller rollback');

    const manual = { date: '2026-10-30', amount_vnd: 20000, category: 'supplies' };
    const key = randomUUID();
    const expense = await request('/expenses', 'demo-a', 'POST', manual, key, 201);
    assert.equal((await request('/expenses', 'demo-a', 'POST', manual, key, 201)).id, expense.id);
    const ocr = await request('/expenses', 'demo-a', 'POST', { ...manual, amount_vnd: 30000, source: 'OCR' }, randomUUID(), 201);
    assert.equal(ocr.confirmed, false);
    const range = { from: '2026-10-01', to: '2026-10-31' };
    assert.equal((await summary.range('demo-a', range)).expense_vnd, 20000);
    await request(`/expenses/${ocr.id}/confirm`, 'demo-b', 'POST', undefined, randomUUID(), 404);
    assert.equal((await request(`/expenses/${ocr.id}/confirm`, 'demo-a', 'POST')).confirmed, true);
    await request(`/expenses/${ocr.id}/confirm`, 'demo-a', 'POST');
    assert.equal((await summary.range('demo-a', range)).expense_vnd, 50000);
    steps.push('Manual expense retry, OCR excluded before confirmation, confirmed once via HTTP');

    await accept('demo-a', { ...sale, sale_id: 'cancel-sale', amount_vnd: 50000, payments: [{ method: 'CASH', amount_vnd: 50000 }] });
    await database.transaction(async client => {
      await client.query("UPDATE fake_sale SET status='CANCELLED' WHERE household_id='demo-a' AND id='cancel-sale'");
      assert.deepEqual(await ledger.reverseSale('demo-a', 'cancel-sale', 'Demo cancellation', client), { duplicate: false });
    });
    assert.deepEqual(await ledger.reverseSale('demo-a', 'cancel-sale', 'Demo cancellation'), { duplicate: true });
    steps.push('Cancellation preserves original Ledger and posts one reversal');

    const csv = await readFile(resolve(__dirname, '../../tests/fixtures/demo-bank.csv'), 'utf8');
    async function upload() {
      const form = new FormData(); form.append('file', new Blob([csv]), 'demo-bank.csv');
      const response = await fetch(`${base}/bank-statements/import`, { method: 'POST', headers: { authorization: `Bearer ${token('demo-a')}` }, body: form });
      assert.equal(response.status, 201); return await response.json() as any;
    }
    assert.equal((await upload()).imported, 1); assert.equal((await upload()).imported, 0);
    const line = (await request('/bank-statements/matches', 'demo-a')).items[0];
    assert.ok(line.suggested_ledger_id);
    await request(`/bank-statements/${line.id}/match`, 'demo-b', 'POST', { action: 'CONFIRM', ledger_id: line.suggested_ledger_id }, randomUUID(), 404);
    const matched = await request(`/bank-statements/${line.id}/match`, 'demo-a', 'POST', { action: 'CONFIRM', ledger_id: line.suggested_ledger_id });
    assert.equal(matched.status, 'MATCHED');
    assert.equal((await request('/bank-statements/matches', 'demo-b')).items.length, 0);
    steps.push('CSV file HTTP upload, duplicate import, suggested match and explicit reconciliation');

    await accept('demo-b', { ...sale, amount_vnd: 990000, payments: [{ method: 'CASH', amount_vnd: 990000 }] });
    const totals = await summary.range('demo-a', range);
    assert.deepEqual(totals, { revenue_vnd: 150000, expense_vnd: 50000, entry_count: 5 });
    assert.equal((await summary.range('demo-b', range)).revenue_vnd, 990000);
    const periods = [randomUUID(), randomUUID()];
    for (const [index, household] of ['demo-a', 'demo-b'].entries()) {
      await database.query("INSERT INTO tax_period(id,household_id,label,start_date,end_date) VALUES ($1,$2,'2026-10','2026-10-01','2026-10-31')", [periods[index], household]);
    }
    const snapshot = await tax.prepareSnapshot('demo-a', periods[0]);
    const other = await tax.prepareSnapshot('demo-b', periods[1]);
    assert.equal((await tax.prepareSnapshot('demo-a', periods[0])).id, snapshot.id);
    assert.deepEqual(snapshot.totals, totals); assert.equal(snapshot.official, false); assert.equal(snapshot.tax_result, null);
    steps.push('Household totals and persisted DRAFT snapshot, deduplication, official=false, tax_result=null');

    // Close the entire app/pool, then read from a newly created PostgreSQL connection.
    await app.close(); app = undefined; database = undefined;
    reader = new Database();
    const restored = new TaxPeriodService(reader, new LedgerSummaryService(reader));
    assert.equal((await restored.readSnapshot('demo-a', snapshot.id)).stale, false);
    const raw = (await reader.query('SELECT revenue_vnd::text,expense_vnd::text FROM tax_draft_snapshot WHERE id=$1', [snapshot.id])).rows[0];
    assert.deepEqual(raw, { revenue_vnd: '150000', expense_vnd: '50000' });
    await assert.rejects(restored.readSnapshot('demo-b', snapshot.id), { status: 404 });
    await assert.rejects(restored.prepareSnapshot('demo-b', periods[0]), { status: 404 });
    assert.deepEqual((await restored.snapshotFreshness('demo-b', [snapshot.id])).items, []);
    assert.equal((await restored.listSnapshots('demo-b')).items.length, 1);
    await reader.transaction(async client => {
      await lockHousehold(client, 'demo-a');
      await client.query("UPDATE ledger_entry SET note='Demo equal-total edit' WHERE household_id='demo-a' AND ref_type='EXPENSE' AND ref_id=$1", [expense.id]);
    });
    const stale = await restored.readSnapshot('demo-a', snapshot.id);
    assert.equal(stale.stale, true); assert.deepEqual(stale.stale_reasons, ['LEDGER_REVISION_CHANGED']);
    assert.deepEqual(stale.totals, totals);
    assert.equal((await restored.readSnapshot('demo-b', other.id)).stale, false);
    steps.push('New PostgreSQL pool reads snapshot after app shutdown; equal-total edit is stale; second household stays fresh and isolated');
    console.log(JSON.stringify({ result: 'PASS', schema: fixture.schema, migration, totals, snapshot_id: snapshot.id,
      source_revision: snapshot.source_revision, current_revision: stale.current_source_revision, steps,
      cleanup: 'Owned schema removed on exit; rerun creates a fresh schema' }, null, 2));
  } finally {
    try {
      if (app) await app.close(); else if (database) await database.onModuleDestroy();
      if (reader) await reader.onModuleDestroy();
    } finally { await fixture.close(); }
  }
}
void main().catch(error => { console.error(error); process.exitCode = 1; });
