
import 'reflect-metadata';

import { randomUUID } from 'node:crypto';
import {
  afterAll,
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
} from '@jest/globals';

import { Database } from '../../common/database';
import { InvoiceRepository } from './invoice.repository';

const describeWithDatabase = process.env.DATABASE_URL
  ? describe
  : describe.skip;

describeWithDatabase('InvoiceRepository - PostgreSQL', () => {
  let database: Database;
  let repository: InvoiceRepository;
  let saleId: string;
  let invoiceId: string;

  const householdId = 'invoice-integration-test-household';

  beforeAll(async () => {
    const originalUrl = process.env.DATABASE_URL;
    if (!originalUrl) throw new Error('Thiếu DATABASE_URL');

    const url = new URL(originalUrl);

    if (
      !['postgres:', 'postgresql:'].includes(url.protocol) ||
      !['localhost', '127.0.0.1'].includes(url.hostname)
    ) {
      throw new Error('Chỉ kiểm thử PostgreSQL local');
    }

    url.pathname = '/taxbook_sales_test';

    try {
      process.env.DATABASE_URL = url.toString();
      database = new Database();
    } finally {
      process.env.DATABASE_URL = originalUrl;
    }

    const check = await database.query<{
      db: string;
      sales_table: string | null;
      invoices_table: string | null;
      household_column: boolean;
    }>(`
      SELECT
        current_database() AS db,
        to_regclass('public.sales')::text AS sales_table,
        to_regclass('public.invoices')::text AS invoices_table,
        EXISTS (
          SELECT 1
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = 'sales'
            AND column_name = 'household_id'
        ) AS household_column
    `);

    const row = check.rows[0];

    if (
      row?.db !== 'taxbook_sales_test' ||
      !row.sales_table ||
      !row.invoices_table ||
      !row.household_column
    ) {
      throw new Error(
        'Database thử nghiệm chưa có schema phù hợp',
      );
    }

    repository = new InvoiceRepository(database);
  }, 20000);

  beforeEach(async () => {
    saleId = randomUUID();
    invoiceId = randomUUID();

    await database.query(
      `INSERT INTO sales (
        id, household_id, client_op_id, device_id,
        local_seq, total_vnd, discount_vnd,
        status, client_created_at
      ) VALUES (
        $1, $2, $3, $4,
        1, 90000, 0, 'SYNCED', NOW()
      )`,
      [
        saleId,
        householdId,
        randomUUID(),
        `invoice-test-${randomUUID()}`,
      ],
    );
  }, 20000);

  afterEach(async () => {
    if (!database || !saleId) return;

    // Chỉ xóa dữ liệu do bài test này tạo
    await database.query(
      'DELETE FROM invoices WHERE sale_id = $1',
      [saleId],
    );

    await database.query(
      'DELETE FROM sales WHERE id = $1 AND household_id = $2',
      [saleId, householdId],
    );
  }, 20000);

  afterAll(async () => {
    if (database) await database.onModuleDestroy();
  }, 20000);

  function makeInput() {
    return {
      id: invoiceId,
      sale_id: saleId,
      series: 'MOCK-DEMO',
      number: invoiceId,
      provider_ref: `MOCK-${invoiceId}`,
      issued_at: new Date().toISOString(),
    };
  }

  it('Lưu hóa đơn vào PostgreSQL', async () => {
    const input = makeInput();

    const saved = await repository.saveIssued(
      householdId,
      input,
    );

    expect(saved.status).toBe('ISSUED');

    const found = await repository.findBySale(
      householdId,
      saleId,
    );

    expect(found?.id).toBe(input.id);
    expect(found?.provider_ref).toBe(input.provider_ref);
  });

  it('Gửi lại không tạo hóa đơn trùng', async () => {
    const input = makeInput();

    const first = await repository.saveIssued(
      householdId,
      input,
    );

    const second = await repository.saveIssued(
      householdId,
      input,
    );

    expect(second.id).toBe(first.id);

    const result = await database.query<{ count: string }>(
      'SELECT count(*)::text AS count FROM invoices WHERE sale_id = $1',
      [saleId],
    );

    expect(result.rows[0].count).toBe('1');
  });

  it('Từ chối hóa đơn khác cho cùng đơn bán', async () => {
    const input = makeInput();

    await repository.saveIssued(householdId, input);

    await expect(
      repository.saveIssued(householdId, {
        ...input,
        id: randomUUID(),
        number: randomUUID(),
      }),
    ).rejects.toMatchObject({ status: 409 });
  });

  it('Hộ khác không thể lưu hóa đơn', async () => {
    await expect(
      repository.saveIssued(
        'another-household',
        makeInput(),
      ),
    ).rejects.toMatchObject({ status: 404 });

    const result = await database.query<{ count: string }>(
      'SELECT count(*)::text AS count FROM invoices WHERE sale_id = $1',
      [saleId],
    );

    expect(result.rows[0].count).toBe('0');
  });
});
