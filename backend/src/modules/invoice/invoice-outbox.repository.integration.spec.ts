
import 'reflect-metadata';

import { InvoiceOutboxWorkerService } from './invoice-outbox-worker.service';
import { MockInvoiceProvider } from './mock-invoice.provider';

import { randomUUID } from 'node:crypto';
import {
  afterAll,
  afterEach,
  beforeAll,
  describe,
  expect,
  it,
} from '@jest/globals';

import { Database } from '../../common/database';
import { InvoiceOutboxRepository } from './invoice-outbox.repository';

const describeWithDatabase = process.env.DATABASE_URL
  ? describe
  : describe.skip;

describeWithDatabase('InvoiceOutbox - PostgreSQL', () => {
  let database: Database;
  let repository: InvoiceOutboxRepository;
  let saleId: string;

  const householdId = 'outbox-integration-test-household';

  beforeAll(async () => {
    const originalUrl = process.env.DATABASE_URL;

    if (!originalUrl) {
      throw new Error('Thiếu DATABASE_URL');
    }

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

    // Kiểm tra database trước khi ghi dữ liệu.
    const check = await database.query<{
      db: string;
      sales_table: string | null;
      outbox_table: string | null;
      household_column: boolean;
    }>(`
      SELECT
        current_database() AS db,
        to_regclass('public.sales')::text AS sales_table,
        to_regclass('public.invoice_outbox')::text AS outbox_table,
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
      !row.outbox_table ||
      !row.household_column
    ) {
      throw new Error(
        'Database thử nghiệm chưa có schema phù hợp',
      );
    }

    repository = new InvoiceOutboxRepository(database);
  }, 20000);

  // Mỗi bài test tạo một đơn bán riêng.
  async function createTestSale(status = 'SYNCED') {
    saleId = randomUUID();

    await database.query(
      `INSERT INTO sales (
        id,
        household_id,
        client_op_id,
        device_id,
        local_seq,
        total_vnd,
        discount_vnd,
        status,
        client_created_at
      )
      VALUES ($1, $2, $3, $4, 1, 90000, 0, $5, NOW())`,
      [
        saleId,
        householdId,
        randomUUID(),
        `outbox-test-${randomUUID()}`,
        status,
      ],
    );
  }

  afterEach(async () => {
    if (!database || !saleId) return;

    // Chỉ xóa dữ liệu do bài test tạo.
    await database.query(
  'DELETE FROM invoices WHERE sale_id = $1',
  [saleId],
);
    await database.query(
      'DELETE FROM invoice_outbox WHERE sale_id = $1',
      [saleId],
    );

    await database.query(
      `DELETE FROM sales
       WHERE id = $1 AND household_id = $2`,
      [saleId, householdId],
    );

    saleId = '';
  }, 20000);

  afterAll(async () => {
    if (database) {
      await database.onModuleDestroy();
    }
  }, 20000);

  it('Tạo PENDING trong PostgreSQL', async () => {
    await createTestSale();

    const result = await repository.enqueue(
      householdId,
      saleId,
    );

    expect(result.status).toBe('PENDING');
    expect(result.attempts).toBe(0);
    expect(result.sale_id).toBe(saleId);
    expect(result.invoice_id).toBeTruthy();

    const saved = await database.query<{
      status: string;
    }>(
      'SELECT status FROM invoice_outbox WHERE sale_id = $1',
      [saleId],
    );

    expect(saved.rows[0].status).toBe('PENDING');
  });

  it('Gửi lại không tạo trùng', async () => {
    await createTestSale();

    const first = await repository.enqueue(
      householdId,
      saleId,
    );

    const second = await repository.enqueue(
      householdId,
      saleId,
    );

    expect(second.id).toBe(first.id);
    expect(second.invoice_id).toBe(first.invoice_id);

    const count = await database.query<{
      total: string;
    }>(
      `SELECT count(*)::text AS total
       FROM invoice_outbox
       WHERE sale_id = $1`,
      [saleId],
    );

    expect(count.rows[0].total).toBe('1');
  });

  it('Hộ khác không thể đưa đơn vào hàng đợi', async () => {
    await createTestSale();

    await expect(
      repository.enqueue('another-household', saleId),
    ).rejects.toMatchObject({
      status: 404,
    });

    const count = await database.query<{
      total: string;
    }>(
      `SELECT count(*)::text AS total
       FROM invoice_outbox
       WHERE sale_id = $1`,
      [saleId],
    );

    expect(count.rows[0].total).toBe('0');
  });

  it('Hai yêu cầu đồng thời không tạo trùng', async () => {
    await createTestSale();

    const [first, second] = await Promise.all([
      repository.enqueue(householdId, saleId),
      repository.enqueue(householdId, saleId),
    ]);

    expect(first.invoice_id).toBe(second.invoice_id);

    const count = await database.query<{
      total: string;
    }>(
      `SELECT count(*)::text AS total
       FROM invoice_outbox
       WHERE sale_id = $1`,
      [saleId],
    );

    expect(count.rows[0].total).toBe('1');
  });

  it('Lấy yêu cầu PENDING và chuyển sang PROCESSING', async () => {
    await createTestSale();

    const queued = await repository.enqueue(
      householdId,
      saleId,
    );

    const claimed = await repository.claimNext();

    expect(claimed).not.toBeNull();
    expect(claimed?.id).toBe(queued.id);
    expect(claimed?.status).toBe('PROCESSING');
    expect(claimed?.attempts).toBe(1);
    expect(claimed?.lease_until).not.toBeNull();
    expect(claimed?.next_retry_at).toBeNull();

    // Yêu cầu đang PROCESSING chưa hết lease
    // thì không được lấy lại ngay.
    const next = await repository.claimNext();

    expect(next).toBeNull();
  }, 20000);

  it('Hai worker không được lấy trùng một yêu cầu', async () => {
    await createTestSale();

    const queued = await repository.enqueue(
      householdId,
      saleId,
    );

    // Giả lập hai worker đồng thời lấy công việc.
    const [first, second] = await Promise.all([
      repository.claimNext(),
      repository.claimNext(),
    ]);

    const claimed = [first, second].filter(
      (job) => job?.id === queued.id,
    );

    expect(claimed).toHaveLength(1);

    const result = await database.query<{
      status: string;
      attempts: number;
    }>(
      `SELECT status, attempts
       FROM invoice_outbox
       WHERE sale_id = $1`,
      [saleId],
    );

    expect(result.rows[0]).toEqual({
      status: 'PROCESSING',
      attempts: 1,
    });
  }, 20000);

  // Giả lập worker đã nhận công việc xử lý
  async function setProcessing(
    jobId: string,
    attempts: number,
    expired = false,
  ) {
    await database.query(
      `UPDATE invoice_outbox
       SET
         status = 'PROCESSING',
         attempts = $2,
         lease_until = CASE
           WHEN $3::boolean
             THEN NOW() - INTERVAL '1 minute'
           ELSE NOW() + INTERVAL '5 minutes'
         END,
         next_retry_at = NULL
       WHERE id = $1`,
      [jobId, attempts, expired],
    );
  }

  it('Lỗi 503 chuyển công việc sang RETRY', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    await setProcessing(job.id, 1);

    const result = await repository.markFailure(
      job.id,
      1,
      'Mock Provider HTTP 503',
    );

    expect(result?.status).toBe('RETRY');
    expect(result?.attempts).toBe(1);
    expect(result?.last_error).toBe(
      'Mock Provider HTTP 503',
    );
    expect(result?.lease_until).toBeNull();
    expect(result?.next_retry_at).not.toBeNull();
    expect(
      new Date(result!.next_retry_at!).getTime(),
    ).toBeGreaterThan(Date.now());
  });

  it('Thất bại lần 5 chuyển sang FAILED', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    await setProcessing(job.id, 5);

    const result = await repository.markFailure(
      job.id,
      5,
      'Provider unavailable',
    );

    expect(result?.status).toBe('FAILED');
    expect(result?.attempts).toBe(5);
    expect(result?.next_retry_at).toBeNull();
    expect(result?.lease_until).toBeNull();
  });

  it('Worker cũ không ghi đè lần xử lý mới', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    // Worker mới đang xử lý lần thứ 2
    await setProcessing(job.id, 2);

    // Worker cũ cố cập nhật kết quả lần thứ 1
    const result = await repository.markFailure(
      job.id,
      1,
      'Lỗi từ worker cũ',
    );

    expect(result).toBeNull();

    const saved = await database.query<{
      status: string;
      attempts: number;
      last_error: string | null;
    }>(
      `SELECT status, attempts, last_error
       FROM invoice_outbox
       WHERE id = $1`,
      [job.id],
    );

    expect(saved.rows[0]).toMatchObject({
      status: 'PROCESSING',
      attempts: 2,
      last_error: null,
    });
  });

  it('Worker hết hạn lease không được cập nhật', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    await setProcessing(job.id, 1, true);

    const result = await repository.markFailure(
      job.id,
      1,
      'Worker đã hết hạn',
    );

    expect(result).toBeNull();
  });

  it('Phát hành thành công và lưu hóa đơn ISSUED', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    await setProcessing(job.id, 1);

    const issued = {
      series: 'MOCK-DEMO',
      number: randomUUID(),
      provider_ref: `MOCK-${job.invoice_id}`,
      issued_at: new Date().toISOString(),
    };

    const result = await repository.completeIssued(
      job.id,
      1,
      issued,
    );

    expect(result?.status).toBe('ISSUED');
    expect(result?.lease_until).toBeNull();
    expect(result?.next_retry_at).toBeNull();

    const saved = await database.query<{
      id: string;
      status: string;
      provider_ref: string;
    }>(
      `SELECT id, status, provider_ref
       FROM invoices
       WHERE sale_id = $1`,
      [saleId],
    );

    expect(saved.rows).toHaveLength(1);
    expect(saved.rows[0]).toMatchObject({
      id: job.invoice_id,
      status: 'ISSUED',
      provider_ref: issued.provider_ref,
    });

    // Hoàn tất lần nữa không được lưu hóa đơn trùng.
    const duplicate = await repository.completeIssued(
      job.id,
      1,
      issued,
    );

    expect(duplicate).toBeNull();
  }, 20000);

  it('Worker cũ không thể hoàn tất hóa đơn', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    // Worker mới đã nhận lần xử lý thứ 2.
    await setProcessing(job.id, 2);

    const result = await repository.completeIssued(
      job.id,
      1,
      {
        series: 'MOCK-DEMO',
        number: randomUUID(),
        provider_ref: `MOCK-${job.invoice_id}`,
        issued_at: new Date().toISOString(),
      },
    );

    expect(result).toBeNull();

    const invoices = await database.query(
      'SELECT id FROM invoices WHERE sale_id = $1',
      [saleId],
    );

    expect(invoices.rows).toHaveLength(0);
  }, 20000);

  it('ROLLBACK nếu đơn bán đã có hóa đơn khác', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    await setProcessing(job.id, 1);

    // Giả lập hóa đơn khác đã tồn tại.
    const existingId = randomUUID();

    await database.query(
      `INSERT INTO invoices (
        id, sale_id, series, number, status
      )
      VALUES ($1, $2, $3, $4, 'ISSUED')`,
      [
        existingId,
        saleId,
        'EXISTING',
        randomUUID(),
      ],
    );

    await expect(
      repository.completeIssued(job.id, 1, {
        series: 'MOCK-DEMO',
        number: randomUUID(),
        provider_ref: `MOCK-${job.invoice_id}`,
        issued_at: new Date().toISOString(),
      }),
    ).rejects.toMatchObject({
      status: 409,
    });

    // Hóa đơn cũ không bị thay đổi.
    const saved = await database.query<{ id: string }>(
      'SELECT id FROM invoices WHERE sale_id = $1',
      [saleId],
    );

    expect(saved.rows).toHaveLength(1);
    expect(saved.rows[0].id).toBe(existingId);

    // Outbox không được chuyển nhầm sang ISSUED.
    const outbox = await database.query<{
      status: string;
    }>(
      'SELECT status FROM invoice_outbox WHERE id = $1',
      [job.id],
    );

    expect(outbox.rows[0].status).toBe('PROCESSING');
  }, 20000);

  it('Mock 503 → RETRY → gửi lại → ISSUED', async () => {
    await createTestSale();

    const job = await repository.enqueue(
      householdId,
      saleId,
    );

    const worker = new InvoiceOutboxWorkerService(
      repository,
      new MockInvoiceProvider(),
    );

    const previousMode = process.env.INVOICE_MOCK_MODE;

    try {
      // Lần đầu: nhà cung cấp trả lỗi 503.
      delete process.env.INVOICE_MOCK_MODE;

      const first = await worker.processNext();

      expect(first).toEqual({
        status: 'RETRY',
        invoice_id: job.invoice_id,
      });

      const retry = await database.query<{
        status: string;
        attempts: number;
      }>(
        `SELECT status, attempts
         FROM invoice_outbox
         WHERE id = $1`,
        [job.id],
      );

      expect(retry.rows[0]).toEqual({
        status: 'RETRY',
        attempts: 1,
      });

      // Chỉ trong database thử nghiệm:
      // giả lập thời gian chờ retry đã kết thúc.
      await database.query(
        `UPDATE invoice_outbox
         SET next_retry_at = NOW() - INTERVAL '1 second'
         WHERE id = $1 AND status = 'RETRY'`,
        [job.id],
      );

      // Lần hai: Mock Provider hoạt động trở lại.
      process.env.INVOICE_MOCK_MODE = 'SUCCESS';

      const second = await worker.processNext();

      expect(second).toEqual({
        status: 'ISSUED',
        invoice_id: job.invoice_id,
      });

      // Kiểm tra trạng thái cuối của Outbox.
      const outbox = await database.query<{
        status: string;
        attempts: number;
      }>(
        `SELECT status, attempts
         FROM invoice_outbox
         WHERE id = $1`,
        [job.id],
      );

      expect(outbox.rows[0]).toEqual({
        status: 'ISSUED',
        attempts: 2,
      });

      // Chỉ có duy nhất một hóa đơn được lưu.
      const invoices = await database.query<{
        id: string;
        status: string;
      }>(
        `SELECT id, status
         FROM invoices
         WHERE sale_id = $1`,
        [saleId],
      );

      expect(invoices.rows).toHaveLength(1);
      expect(invoices.rows[0]).toEqual({
        id: job.invoice_id,
        status: 'ISSUED',
      });
    } finally {
      // Khôi phục cấu hình môi trường.
      if (previousMode === undefined) {
        delete process.env.INVOICE_MOCK_MODE;
      } else {
        process.env.INVOICE_MOCK_MODE = previousMode;
      }
    }
  }, 20000);
});
