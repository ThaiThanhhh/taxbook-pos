import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { parse } from 'csv-parse/sync';
import { createHash, randomUUID } from 'node:crypto';
import { Database } from '../../common/database';
import { invalid } from '../../common/http';
import { BankMatchInput, BankQuery } from './dto';
import { assertOpen, cursor, date, idempotent, lockHousehold, money, page, uuid } from './helpers';

export function parseBankCsv(csv: string) {
  let rows: Record<string, string>[];
  try {
    rows = parse(csv, { bom: true, columns: headers => {
      if (headers.join(',') !== 'txn_date,amount_vnd,description') throw new Error('Invalid columns');
      return headers;
    }, skip_empty_lines: true, max_record_size: 10000 });
  } catch { invalid('file', 'Expected CSV headers txn_date,amount_vnd,description and valid CSV rows'); }
  if (!rows.length || rows.length > 5000) invalid('file', 'Expected 1–5000 rows');
  return rows.map((row, index) => {
    const field = `file.row[${index + 2}]`;
    date(row.txn_date, `${field}.txn_date`);
    if (!/^-?\d+$/.test(row.amount_vnd)) invalid(`${field}.amount_vnd`, 'Expected integer VND');
    const amount = money(Number(row.amount_vnd), `${field}.amount_vnd`, true);
    if (row.description.length > 2000) invalid(`${field}.description`, 'Maximum 2000 characters');
    return { txn_date: row.txn_date, amount_vnd: amount, description: row.description };
  });
}

@Injectable()
export class BankService {
  constructor(private readonly database: Database) {}

  async import(household: string, csv: string) {
    const rows = parseBankCsv(csv);
    const digest = createHash('sha256').update(csv).digest('hex');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      let imported = 0;
      for (const [index, row] of rows.entries()) {
        const result = await client.query(`INSERT INTO bank_statement_line
          (id,household_id,txn_date,amount_vnd,description,import_hash,row_number)
          VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (household_id,import_hash,row_number) DO NOTHING RETURNING id`,
        [randomUUID(), household, row.txn_date, row.amount_vnd, row.description, digest, index]);
        imported += result.rows.length;
      }
      // Matching always requires explicit user confirmation in this first implementation.
      return { imported, auto_matched: 0, unmatched: imported };
    });
  }

  async list(household: string, query: BankQuery) {
    const scope = { household, status: query.status };
    const after = cursor(query.cursor, scope);
    const result = await this.database.query(`SELECT b.id,b.txn_date::text,b.amount_vnd::float8,b.description,b.matched_ledger_id,
      CASE WHEN b.matched_ledger_id IS NULL THEN 'UNMATCHED' ELSE 'MATCHED' END AS status,
      (SELECT CASE WHEN count(*)=1 THEN min(l.id::text) END FROM ledger_entry l
       WHERE l.household_id=b.household_id AND l.type='BANK' AND l.entry_date=b.txn_date
       AND l.amount_vnd=b.amount_vnd AND NOT EXISTS
       (SELECT 1 FROM bank_statement_line used WHERE used.household_id=b.household_id AND used.matched_ledger_id=l.id)) AS suggested_ledger_id
      FROM bank_statement_line b WHERE b.household_id=$1
      AND ($2::text IS NULL OR ($2='MATCHED')=(b.matched_ledger_id IS NOT NULL))
      AND ($3::date IS NULL OR (b.txn_date,b.id)>($3::date,$4::uuid)) ORDER BY b.txn_date,b.id LIMIT $5`,
    [household, query.status ?? null, after?.[0] ?? null, after?.[1] ?? null, query.limit + 1]);
    return page(result.rows as {id: string; txn_date: string}[], query.limit, 'txn_date', scope);
  }

  async match(household: string, id: string, key: string, input: BankMatchInput) {
    uuid(id, 'line_id');
    if (input.action === 'CONFIRM') uuid(input.ledger_id ?? '', 'ledger_id');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      return idempotent(client, household, 'bank:match', key, { id, ...input }, async () => {
        const result = await client.query('SELECT txn_date::text,amount_vnd::float8 FROM bank_statement_line WHERE household_id=$1 AND id=$2', [household, id]);
        if (!result.rows.length) throw new NotFoundException('Bank line not found');
        await assertOpen(client, household, result.rows[0].txn_date);
        if (input.action === 'CONFIRM') {
          const ledger = await client.query("SELECT entry_date::text,amount_vnd::float8 FROM ledger_entry WHERE household_id=$1 AND id=$2 AND type='BANK'", [household, input.ledger_id]);
          if (!ledger.rows.length) throw new NotFoundException('Bank ledger entry not found');
          if (ledger.rows[0].amount_vnd !== result.rows[0].amount_vnd) throw new ConflictException('Amounts do not match');
          await assertOpen(client, household, ledger.rows[0].entry_date);
          const used = await client.query('SELECT id FROM bank_statement_line WHERE household_id=$1 AND matched_ledger_id=$2 AND id<>$3', [household, input.ledger_id, id]);
          if (used.rows.length) throw new ConflictException('Ledger entry already matched');
        } else {
          const matched = await client.query(`SELECT l.entry_date::text FROM bank_statement_line b JOIN ledger_entry l ON l.household_id=b.household_id AND l.id=b.matched_ledger_id WHERE b.household_id=$1 AND b.id=$2`, [household, id]);
          if (matched.rows.length) await assertOpen(client, household, matched.rows[0].entry_date);
        }
        const updated = await client.query(`UPDATE bank_statement_line SET matched_ledger_id=$3 WHERE household_id=$1 AND id=$2
          RETURNING id,txn_date::text,amount_vnd::float8,description,matched_ledger_id,
          CASE WHEN matched_ledger_id IS NULL THEN 'UNMATCHED' ELSE 'MATCHED' END AS status`,
        [household, id, input.action === 'CONFIRM' ? input.ledger_id : null]);
        return updated.rows[0];
      });
    });
  }
}
