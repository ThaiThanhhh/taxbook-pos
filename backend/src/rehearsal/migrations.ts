import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Pool } from 'pg';

export interface Migration { id: string; sql: string }
export async function migrationPlan(): Promise<Migration[]> {
  const files = ['src/modules/ledger/schema.sql', 'src/modules/tax/schema.sql',
    'migrations/proposals/tax-draft-snapshot.sql', 'migrations/proposals/snapshot-list-index.sql'];
  return Promise.all(files.map(async (file, i) => ({ id: `rehearsal-${i + 1}-${file.split('/').at(-1)}`,
    sql: (await readFile(resolve(__dirname, '../..', file), 'utf8')).replace(/\r\n/g, '\n') })));
}

/** Test-only runner. IDs are deliberately NOT team production migration numbers.
 * All pending DDL and history commit together, or all roll back together.
 */
export async function migrate(pool: Pool, plan: Migration[], rollback = false) {
  const client = await pool.connect();
  let discard = false;
  try {
    await client.query('BEGIN');
    const schema = (await client.query('SELECT current_schema() AS name')).rows[0].name as string;
    if (!/^taxbook_rehearsal_[a-f0-9]{32}$/.test(schema)) throw new Error('Runner requires an isolated rehearsal schema');
    await client.query('SELECT pg_advisory_xact_lock(hashtext(current_schema()), 9019)');
    await client.query(`CREATE TABLE IF NOT EXISTS rehearsal_migration (
      id text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT clock_timestamp())`);
    const history = (await client.query('SELECT id,checksum FROM rehearsal_migration ORDER BY id')).rows;
    if (new Set(plan.map(m => m.id)).size !== plan.length) throw new Error('Duplicate migration ID');
    if (history.some((row, i) => row.id !== plan[i]?.id)) throw new Error('Migration history is not a prefix of this plan');
    const applied: string[] = [];
    for (const migration of plan) {
      const checksum = createHash('sha256').update(migration.sql.replace(/\r\n/g, '\n')).digest('hex');
      const prior = history.find(row => row.id === migration.id);
      if (prior) {
        if (prior.checksum !== checksum) throw new Error(`Migration checksum mismatch: ${migration.id}`);
        continue;
      }
      await client.query(migration.sql);
      await client.query('INSERT INTO rehearsal_migration(id,checksum) VALUES ($1,$2)', [migration.id, checksum]);
      applied.push(migration.id);
    }
    await client.query(rollback ? 'ROLLBACK' : 'COMMIT');
    return { applied, skipped: history.length, rolled_back: rollback };
  } catch (error) {
    try { await client.query('ROLLBACK'); } catch { discard = true; }
    throw error;
  } finally { client.release(discard); }
}
