import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Database } from './common/database';

async function main() {
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  const database = new Database();
  try {
    await database.transaction(async client => {
      const tables = await client.query("SELECT tablename FROM pg_tables WHERE schemaname = 'public'");
      if (tables.rows.length) throw new Error('Bootstrap requires an empty public schema. Use reviewed migrations for an existing database.');
      for (const module of ['ledger', 'tax']) {
        await client.query(await readFile(resolve('src/modules', module, 'schema.sql'), 'utf8'));
      }
    });
    console.log('Created Ledger & Tax tables in empty local database. No tax parameters approved or seeded.');
  } finally { await database.onModuleDestroy(); }
}
void main().catch(error => { console.error(error.message); process.exitCode = 1; });
