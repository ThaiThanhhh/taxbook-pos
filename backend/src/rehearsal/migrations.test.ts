import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { migrate, migrationPlan } from './migrations';
import { sandbox } from './sandbox';
import { Database } from '../common/database';
import { TaxPeriodService } from '../modules/tax/tax-period.service';
import { LedgerSummaryService } from '../modules/ledger/ledger-summary.service';
import { Pool } from 'pg';

test('12 migrations use plan order for partial upgrade and replay, rejecting gaps, reordered pending IDs and checksum drift', async () => {
  const fixture = await sandbox();
  const plan = Array.from({ length: 12 }, (_, i) => ({ id: `rehearsal-${i + 1}-probe`,
    sql: `CREATE TABLE migration_probe_${i + 1}(id integer)` }));
  try {
    const prefix = plan.slice(0, 10);
    assert.deepEqual((await migrate(fixture.pool, prefix)).applied, prefix.map(m => m.id));
    // Lexicographic SQL order puts migration 10 before 2; both replay and upgrade must work.
    assert.deepEqual(await migrate(fixture.pool, prefix), { applied: [], skipped: 10, rolled_back: false });

    const before = (await fixture.pool.query('SELECT * FROM rehearsal_migration ORDER BY id')).rows;
    const invalidPlans = [
      // An unapplied migration moved ahead of an applied one breaks the prefix.
      [...plan.slice(0, 9), plan[10], plan[9], plan[11]],
      // Removing an applied ID must not silently discard its history.
      plan.filter((_, i) => i !== 4),
    ];
    for (const invalidPlan of invalidPlans) {
      await assert.rejects(migrate(fixture.pool, invalidPlan), /not a prefix/);
      assert.deepEqual((await fixture.pool.query('SELECT * FROM rehearsal_migration ORDER BY id')).rows, before);
      assert.equal((await fixture.pool.query("SELECT to_regclass('migration_probe_11') AS name")).rows[0].name, null);
    }
    await assert.rejects(migrate(fixture.pool, plan.map((m, i) => i === 9 ? { ...m, sql: `${m.sql}; -- changed` } : m)), /checksum mismatch: rehearsal-10-probe/);
    assert.deepEqual((await fixture.pool.query('SELECT * FROM rehearsal_migration ORDER BY id')).rows, before);

    // A missing applied row in the middle of history is not a valid prefix either.
    const removed = (await fixture.pool.query('DELETE FROM rehearsal_migration WHERE id=$1 RETURNING *', [plan[4].id])).rows[0];
    await assert.rejects(migrate(fixture.pool, plan), /not a prefix/);
    await fixture.pool.query('INSERT INTO rehearsal_migration(id,checksum,applied_at) VALUES ($1,$2,$3)', [removed.id, removed.checksum, removed.applied_at]);

    assert.deepEqual(await migrate(fixture.pool, plan), { applied: plan.slice(10).map(m => m.id), skipped: 10, rolled_back: false });
    assert.deepEqual(await migrate(fixture.pool, plan), { applied: [], skipped: 12, rolled_back: false });
    // Reinsert the same history in a different physical order, with equal times:
    // neither result order nor applied_at is the source of plan ordering.
    const history = (await fixture.pool.query('SELECT * FROM rehearsal_migration ORDER BY id DESC')).rows;
    await fixture.pool.query('DELETE FROM rehearsal_migration');
    for (const row of history) {
      await fixture.pool.query("INSERT INTO rehearsal_migration(id,checksum,applied_at) VALUES ($1,$2,'2026-11-01T00:00:00Z')", [row.id, row.checksum]);
    }
    assert.deepEqual(await migrate(fixture.pool, plan), { applied: [], skipped: 12, rolled_back: false });
    assert.equal((await fixture.pool.query("SELECT count(*) FROM pg_tables WHERE schemaname=current_schema() AND tablename LIKE 'migration_probe_%'")).rows[0].count, '12');
  } finally { await fixture.close(); }
});

test('rehearsal rejects missing/test-unsafe URLs and refuses the public schema before writing history', async () => {
  const value = process.env.TEST_DATABASE_URL;
  try {
    delete process.env.TEST_DATABASE_URL;
    await assert.rejects(sandbox(), /TEST_DATABASE_URL is required/);
    process.env.TEST_DATABASE_URL = 'postgresql://localhost/production';
    await assert.rejects(sandbox(), /disposable PostgreSQL database/);
  } finally {
    if (value === undefined) delete process.env.TEST_DATABASE_URL; else process.env.TEST_DATABASE_URL = value;
  }
  if (!value) throw new Error('TEST_DATABASE_URL is required for the PostgreSQL safety check');
  const url = new URL(value); url.searchParams.set('options', '-c search_path=public');
  const pool = new Pool({ connectionString: url.toString() });
  try {
    await assert.rejects(migrate(pool, await migrationPlan()), /isolated rehearsal schema/);
    assert.equal((await pool.query("SELECT to_regclass('public.rehearsal_migration') AS name")).rows[0].name, null);
  } finally { await pool.end(); }
});

test('PostgreSQL rehearsal: fresh, tracking, replay, checksum, atomic failure, dry rollback, concurrent runners and legacy upgrade', async () => {
  const plan = await migrationPlan();
  const fresh = await sandbox();
  try {
    assert.equal((await migrate(fresh.pool, plan, true)).applied.length, 4);
    assert.equal((await fresh.pool.query("SELECT to_regclass('ledger_entry') AS table_name")).rows[0].table_name, null);
    const failure = { id: 'rehearsal-5-failure', sql: 'CREATE TABLE rollback_probe(id int); SELECT * FROM missing_rehearsal_table;' };
    await assert.rejects(migrate(fresh.pool, [...plan, failure]), /missing_rehearsal_table/);
    assert.equal((await fresh.pool.query("SELECT count(*) FROM pg_tables WHERE schemaname=current_schema()")).rows[0].count, '0');
    const results = await Promise.all([migrate(fresh.pool, plan), migrate(fresh.pool, plan)]);
    assert.deepEqual(results.map(r => r.applied.length).sort(), [0, 4]);
    assert.equal((await migrate(fresh.pool, plan)).skipped, 4);
    assert.equal((await migrate(fresh.pool, plan.map(m => ({ ...m, sql: m.sql.replace(/\n/g, '\r\n') })))).skipped, 4);
    await assert.rejects(migrate(fresh.pool, [{ ...plan[0], sql: `${plan[0].sql}\n-- changed` }, ...plan.slice(1)]), /checksum mismatch/);
    await assert.rejects(migrate(fresh.pool, plan.slice(1)), /not a prefix/);
    await assert.rejects(migrate(fresh.pool, [...plan, failure]), /missing_rehearsal_table/);
    assert.equal((await fresh.pool.query('SELECT count(*) FROM rehearsal_migration')).rows[0].count, '4');
    assert.equal((await fresh.pool.query("SELECT to_regclass('rollback_probe') AS name")).rows[0].name, null);
  } finally { await fresh.close(); }

  const legacy = await sandbox();
  try {
    // PR #8 has no history table. Never claim its baseline was run by this runner.
    await legacy.pool.query(plan[0].sql); await legacy.pool.query(plan[1].sql);
    const id = randomUUID();
    await legacy.pool.query(`INSERT INTO ledger_entry(id,household_id,book,entry_date,type,amount_vnd,ref_type,ref_id,note)
      VALUES ($1,'legacy','REVENUE','2026-10-30','REVENUE',123000,'SALE','old-sale','preserve')`, [id]);
    const period = randomUUID();
    await legacy.pool.query("INSERT INTO tax_period(id,household_id,label,start_date,end_date) VALUES ($1,'legacy','old','2026-10-01','2026-10-31')", [period]);
    const before = (await legacy.pool.query('SELECT * FROM ledger_entry')).rows;
    assert.equal((await migrate(legacy.pool, plan.slice(2), true)).applied.length, 2);
    assert.equal((await legacy.pool.query("SELECT to_regclass('tax_draft_snapshot') AS name")).rows[0].name, null);
    assert.deepEqual((await legacy.pool.query('SELECT * FROM ledger_entry')).rows, before);
    await assert.rejects(migrate(legacy.pool, [...plan.slice(2), { id: 'rehearsal-5-upgrade-failure', sql: 'SELECT * FROM missing_upgrade_table' }]), /missing_upgrade_table/);
    assert.equal((await legacy.pool.query("SELECT to_regclass('tax_draft_snapshot') AS name")).rows[0].name, null);
    assert.equal((await legacy.pool.query("SELECT count(*) FROM information_schema.columns WHERE table_schema=current_schema() AND table_name='ledger_household_lock' AND column_name='ledger_revision'")).rows[0].count, '0');
    assert.deepEqual((await legacy.pool.query('SELECT * FROM ledger_entry')).rows, before);
    await migrate(legacy.pool, plan.slice(2));
    assert.deepEqual((await legacy.pool.query('SELECT * FROM ledger_entry')).rows, before);
    assert.equal((await legacy.pool.query('SELECT count(*) FROM tax_period')).rows[0].count, '1');
    await legacy.pool.query("UPDATE ledger_entry SET note='after upgrade' WHERE id=$1", [id]);
    assert.equal((await legacy.pool.query("SELECT ledger_revision::text AS revision FROM ledger_household_lock WHERE household_id='legacy'")).rows[0].revision, '1');
    assert.equal((await migrate(legacy.pool, plan.slice(2))).skipped, 2);
    const previous = process.env.DATABASE_URL;
    process.env.DATABASE_URL = legacy.connectionString;
    const database = new Database();
    try {
      const tax = new TaxPeriodService(database, new LedgerSummaryService(database));
      const saved = await tax.prepareSnapshot('legacy', period);
      assert.equal(saved.totals.revenue_vnd, 123000);
      assert.equal(saved.source_revision, '1');
      assert.equal((await tax.readSnapshot('legacy', saved.id)).stale, false);
    } finally {
      await database.onModuleDestroy();
      if (previous === undefined) delete process.env.DATABASE_URL; else process.env.DATABASE_URL = previous;
    }
  } finally { await legacy.close(); }
});
