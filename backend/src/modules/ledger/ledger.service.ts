import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Database, SqlClient } from '../../common/database';
import { invalid } from '../../common/http';
import { ExpenseInput, LedgerQuery } from './dto';
import { assertOpen, cursor, date, hash, idempotent, lockHousehold, money, page, uuid } from './helpers';

const expenseColumns = "id, date::text, amount_vnd::float8, category, vendor, image_url, source, confirmed, confirmed_at";
const ledgerColumns = 'id, book, entry_date::text, type, amount_vnd::float8, ref_type, ref_id, category, note';
interface ExpenseRow {
  id: string; date: string; amount_vnd: number; category: string;
  vendor: string | null; image_url: string | null; source: string;
  confirmed: boolean; confirmed_at: Date | null;
}
export interface SalePosting {
  sale_id: string; entry_date: string; amount_vnd: number; sector_code: string;
  payments: { method: 'CASH' | 'QR_TRANSFER' | 'CARD'; amount_vnd: number }[];
}

@Injectable()
export class LedgerService {
  constructor(private readonly database: Database) {}

  async list(household: string, query: LedgerQuery) {
    if (query.from && query.to && query.from > query.to) invalid('to', 'Must be on or after from');
    const scope = { household, book: query.book, from: query.from, to: query.to };
    const after = cursor(query.cursor, scope);
    const result = await this.database.query(`SELECT ${ledgerColumns} FROM ledger_entry
      WHERE household_id=$1 AND ($2::text IS NULL OR book=$2)
      AND ($3::date IS NULL OR entry_date >= $3) AND ($4::date IS NULL OR entry_date <= $4)
      AND ($5::date IS NULL OR (entry_date,id) > ($5::date,$6::uuid))
      ORDER BY entry_date,id LIMIT $7`,
    [household, query.book ?? null, query.from ?? null, query.to ?? null, after?.[0] ?? null, after?.[1] ?? null, query.limit + 1]);
    return page(result.rows as { id: string; entry_date: string }[], query.limit, 'entry_date', scope);
  }

  async createExpense(household: string, key: string, input: ExpenseInput) {
    date(input.date); money(input.amount_vnd);
    if (!input.category.trim() || input.amount_vnd <= 0) invalid('expense', 'Category and positive amount required');
    const normalized = { ...input, source: input.source ?? 'MANUAL' };
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      return idempotent(client, household, 'expense:create', key, normalized, async () => {
        await assertOpen(client, household, input.date);
        const id = randomUUID();
        const confirmed = normalized.source === 'MANUAL';
        await client.query(`INSERT INTO expense (id,household_id,date,amount_vnd,category,vendor,image_url,source,confirmed,confirmed_at)
          VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
        [id, household, input.date, input.amount_vnd, input.category, input.vendor ?? null, input.image_url ?? null,
          normalized.source, confirmed, confirmed ? new Date() : null]);
        if (confirmed) await this.postExpense(client, household, id, input);
        return this.getExpense(client, household, id);
      });
    });
  }

  async confirmExpense(household: string, id: string, key: string) {
    uuid(id, 'expense_id');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      return idempotent(client, household, 'expense:confirm', key, { id }, async () => {
        const expense = await this.getExpense(client, household, id);
        if (!expense.confirmed) {
          await assertOpen(client, household, expense.date);
          await client.query('UPDATE expense SET confirmed=true,confirmed_at=now() WHERE household_id=$1 AND id=$2', [household, id]);
          await this.postExpense(client, household, id, expense);
        }
        return this.getExpense(client, household, id);
      });
    });
  }

  private async getExpense(client: SqlClient, household: string, id: string) {
    const result = await client.query<ExpenseRow>(`SELECT ${expenseColumns} FROM expense WHERE household_id=$1 AND id=$2`, [household, id]);
    if (!result.rows.length) throw new NotFoundException('Expense not found');
    const row = result.rows[0];
    return { ...row, confirmed_at: row.confirmed_at ? new Date(row.confirmed_at).toISOString() : null,
      ocr_status: row.source === 'OCR' ? 'DRAFT' : 'NONE' };
  }

  private async postExpense(client: SqlClient, household: string, id: string, expense: Record<string, any>) {
    await client.query(`INSERT INTO ledger_entry (id,household_id,book,entry_date,type,amount_vnd,ref_type,ref_id,category)
      VALUES ($1,$2,'EXPENSE',$3,'EXPENSE',$4,'EXPENSE',$5,$6)`,
    [randomUUID(), household, expense.date, expense.amount_vnd, id, expense.category]);
  }

  /** Internal integration seam for Sales. Caller must only pass persisted, accepted sales. */
  async recordSale(household: string, input: SalePosting) {
    date(input.entry_date); money(input.amount_vnd);
    if (!input.sale_id?.trim() || !['GOODS_DISTRIBUTION','SERVICE','PRODUCTION_TRANSPORT','OTHER'].includes(input.sector_code)) {
      invalid('sale', 'Sale ID and valid sector required');
    }
    let total = 0;
    for (const payment of input.payments) {
      money(payment.amount_vnd);
      if (!['CASH','QR_TRANSFER','CARD'].includes(payment.method)) invalid('payments', 'Unknown payment method');
      total += payment.amount_vnd;
      money(total);
    }
    if (total !== input.amount_vnd) invalid('payments', 'Payments must equal sale total');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      // Deterministic fingerprint guards retries without relying on caller-generated UUIDs.
      const prior = await client.query("SELECT note FROM ledger_entry WHERE household_id=$1 AND ref_type='SALE' AND ref_id=$2", [household, input.sale_id]);
      const fingerprint = hash(input);
      if (prior.rows.length) {
        if (prior.rows[0].note !== fingerprint) throw new ConflictException('Sale already posted with different data');
        return { duplicate: true };
      }
      await assertOpen(client, household, input.entry_date);
      await client.query(`INSERT INTO ledger_entry (id,household_id,book,entry_date,type,amount_vnd,ref_type,ref_id,category,note)
        VALUES ($1,$2,'REVENUE',$3,'REVENUE',$4,'SALE',$5,$6,$7)`,
      [randomUUID(), household, input.entry_date, input.amount_vnd, input.sale_id, input.sector_code, fingerprint]);
      // Aggregate multiple payments of the same type to avoid duplicate payment entries.
      for (const type of ['CASH', 'BANK']) {
        const amount = input.payments.filter(p => (p.method === 'CASH' ? 'CASH' : 'BANK') === type).reduce((sum, p) => sum + p.amount_vnd, 0);
        if (amount) await client.query(`INSERT INTO ledger_entry (id,household_id,book,entry_date,type,amount_vnd,ref_type,ref_id)
          VALUES ($1,$2,$3,$4,$3,$5,'SALE_PAYMENT',$6)`, [randomUUID(), household, type, input.entry_date, amount, input.sale_id]);
      }
      return { duplicate: false };
    });
  }

  /** Reversal preserves the original entries; Sales must retry via an outbox on failure. */
  async reverseSale(household: string, saleId: string, reason: string) {
    if (!reason?.trim() || reason.length > 500) invalid('reason', 'Expected 1–500 characters');
    return this.database.transaction(async client => {
      await lockHousehold(client, household);
      const original = await client.query(`SELECT ${ledgerColumns} FROM ledger_entry
        WHERE household_id=$1 AND ref_id=$2 AND ref_type IN ('SALE','SALE_PAYMENT')`, [household, saleId]);
      if (!original.rows.length) throw new NotFoundException('Posted sale not found');
      const previous = await client.query("SELECT id FROM ledger_entry WHERE household_id=$1 AND ref_type='SALE_REVERSAL' AND ref_id=$2", [household, original.rows[0].id]);
      if (previous.rows.length) return { duplicate: true };
      for (const row of original.rows) {
        await assertOpen(client, household, row.entry_date);
        await client.query(`INSERT INTO ledger_entry (id,household_id,book,entry_date,type,amount_vnd,ref_type,ref_id,category,note)
          VALUES ($1,$2,$3,$4,$5,$6,'SALE_REVERSAL',$7,$8,$9)`,
        [randomUUID(), household, row.book, row.entry_date, row.type, -row.amount_vnd, row.id, row.category, reason]);
      }
      return { duplicate: false };
    });
  }
}
