import { randomUUID } from 'node:crypto';
import { Pool } from 'pg';

export async function sandbox() {
  const value = process.env.TEST_DATABASE_URL;
  if (!value) throw new Error('TEST_DATABASE_URL is required; DATABASE_URL is never used by the rehearsal runner');
  const url = new URL(value);
  if (!['postgres:', 'postgresql:'].includes(url.protocol) || !/(^|[_-])test([_-]|$)/i.test(decodeURIComponent(url.pathname.slice(1)))) {
    throw new Error('Use a disposable PostgreSQL database with a name containing a separate test component, e.g. ledger_test');
  }
  // Do not inherit a caller-controlled search_path. Every run owns exactly one schema.
  url.searchParams.delete('options');
  const admin = new Pool({ connectionString: url.toString() });
  const schema = `taxbook_rehearsal_${randomUUID().replaceAll('-', '')}`;
  try { await admin.query(`CREATE SCHEMA "${schema}"`); }
  catch (error) { await admin.end(); throw error; }
  url.searchParams.set('options', `-c search_path=${schema}`);
  const pool = new Pool({ connectionString: url.toString() });
  return { pool, schema, connectionString: url.toString(), async close() {
    await pool.end();
    try {
      if (!/^taxbook_rehearsal_[a-f0-9]{32}$/.test(schema)) throw new Error('Invalid cleanup target');
      await admin.query(`DROP SCHEMA "${schema}" CASCADE`);
    } finally { await admin.end(); }
  } };
}
