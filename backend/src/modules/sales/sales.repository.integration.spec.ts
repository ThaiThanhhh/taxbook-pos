
import 'reflect-metadata';

import { randomUUID } from 'node:crypto';
import {
  afterAll,
  beforeAll,
  describe,
  expect,
  it,
} from '@jest/globals';

import { Database } from '../../common/database';
import { SalesRepository } from './sales.repository';
import { LedgerService } from '../ledger/ledger.service';
import type { SyncSaleDto } from './dto/sync-sales.dto';


const describeWithDatabase = process.env.DATABASE_URL
  ? describe
  : describe.skip;

describeWithDatabase('SalesRepository - PostgreSQL Integration', () => {

  const TEST_DATABASE = 'taxbook_sales_test';

  let database: Database;
  let repository: SalesRepository;

  const testOperationIds: string[] = [];
  const householdId = 'household-test-001';

  const amounts = {
    totalVnd: 90000,
    discountVnd: 0,
  };

  // Tạo dữ liệu thử nghiệm riêng cho mỗi lần chạy
  function makeSale(): SyncSaleDto {
    return {
      client_op_id: randomUUID(),
      local_seq: 1,
      client_created_at: new Date().toISOString(),
      items: [
        {
          product_id: 'p-001',
          qty: 2,
          unit_price_vnd: 45000,
        },
      ],
      payments: [
        {
          method: 'CASH',
          amount_vnd: 90000,
        },
      ],
    } as SyncSaleDto;
  }

  beforeAll(async () => {
    const originalUrl = process.env.DATABASE_URL;

    if (!originalUrl) {
      throw new Error('Thiếu DATABASE_URL trong .env');
    }

    const url = new URL(originalUrl);

    // Chỉ cho phép PostgreSQL chạy trên máy cá nhân
    if (
      !['postgres:', 'postgresql:'].includes(url.protocol) ||
      !['127.0.0.1', 'localhost'].includes(url.hostname)
    ) {
      throw new Error(
        'Chỉ được kiểm thử trên PostgreSQL local',
      );
    }

    // Luôn ép kết nối sang database thử nghiệm
    url.pathname = `/${TEST_DATABASE}`;

    try {
      process.env.DATABASE_URL = url.toString();
      database = new Database();
    } finally {
      process.env.DATABASE_URL = originalUrl;
    }

    // Xác nhận database thật trước khi ghi
    const result = await database.query<{ db: string }>(
      'SELECT current_database() AS db',
    );

    if (result.rows[0]?.db !== TEST_DATABASE) {
      throw new Error(
        'Sai database! Dừng kiểm thử để bảo vệ dữ liệu.',
      );
    }

    repository = new SalesRepository(database);
  }, 20000);

  // Chỉ xóa các đơn thử nghiệm do file này tạo ra
  afterAll(async () => {
    if (!database) return;

    try {
      for (const operationId of testOperationIds) {
        await database.transaction(async (client) => {
          const result = await client.query<{ id: string }>(
            `SELECT id FROM sales
             WHERE client_op_id = $1`,
            [operationId],
          );

          const saleId = result.rows[0]?.id;
          if (!saleId) return;

          await client.query(
            'DELETE FROM payments WHERE sale_id = $1',
            [saleId],
          );
          // Xóa bút toán thử nghiệm trước khi xóa đơn bán
          await client.query(
            `DELETE FROM ledger_entry
             WHERE household_id = $1
               AND ref_id = $2
               AND ref_type IN ('SALE', 'SALE_PAYMENT')`,
            [householdId, saleId],
          );
          await client.query(
            'DELETE FROM sale_items WHERE sale_id = $1',
            [saleId],
          );

          await client.query(
            'DELETE FROM sales WHERE id = $1',
            [saleId],
          );
        });
      }
    } finally {
      await database.onModuleDestroy();
    }
  }, 20000);

  it('Lưu đủ 3 bảng và chống trùng đơn', async () => {
    const sale = makeSale();
    const deviceId = `test-${randomUUID()}`;

    testOperationIds.push(sale.client_op_id);

   const created = await repository.createSale(
  householdId,
  deviceId,
  sale,
  amounts,
);

    expect(created.duplicate).toBe(false);
    expect(created.status).toBe('SYNCED');


const savedSale = await database.query<{
  id: string;
  household_id: string;
}>(
  `SELECT id, household_id
   FROM sales
   WHERE id = $1`,
  [created.sale_id],
);


    const savedItems = await database.query(
      'SELECT id FROM sale_items WHERE sale_id = $1',
      [created.sale_id],
    );

    const savedPayments = await database.query(
      'SELECT id FROM payments WHERE sale_id = $1',
      [created.sale_id],
    );

    expect(savedSale.rows).toHaveLength(1);
    expect(savedSale.rows[0].household_id).toBe(
  householdId,
);
    expect(savedItems.rows).toHaveLength(1);
    expect(savedPayments.rows).toHaveLength(1);

    // Gửi lại chính đơn hàng vừa lưu
    const duplicate = await repository.createSale(
  householdId,
  deviceId,
  sale,
  amounts,
);

    expect(duplicate.duplicate).toBe(true);
    expect(duplicate.sale_id).toBe(created.sale_id);

    // Hộ kinh doanh sở hữu đơn được phép truy vấn
    const ownerSale = await repository.findById(
      householdId,
      created.sale_id,
    );

    expect(ownerSale).not.toBeNull();

    // Hộ kinh doanh khác không được xem đơn này
    const otherHouseholdSale = await repository.findById(
      'household-other-999',
      created.sale_id,
    );

    expect(otherHouseholdSale).toBeNull();

  }, 20000);

  it('ROLLBACK nếu lưu thanh toán thất bại', async () => {
    const sale = makeSale();
    const deviceId = `test-${randomUUID()}`;

    testOperationIds.push(sale.client_op_id);

    // Cố tình sử dụng phương thức sai để DB báo lỗi
    sale.payments[0].method = 'INVALID_METHOD' as
      typeof sale.payments[0]['method'];

    await expect(
      repository.createSale(
  householdId,
  deviceId,
  sale,
  amounts,
)
    ).rejects.toThrow();

    // Sau lỗi, đơn hàng không được tồn tại
    const result = await database.query(
      `SELECT id FROM sales
       WHERE client_op_id = $1`,
      [sale.client_op_id],
    );

    expect(result.rows).toHaveLength(0);
  }, 20000);

  it('ROLLBACK cả Sales và Ledger khi gặp lỗi', async () => {
    const sale = makeSale();
    const deviceId = `test-${randomUUID()}`;

    const ledgerService = new LedgerService(database);

    let insertedSaleId: string | undefined;

    await expect(
      repository.createSale(
        householdId,
        deviceId,
        sale,
        amounts,
        async (client, saleId) => {
          insertedSaleId = saleId;

          // Ghi doanh thu bằng LedgerService thật.
          // sector_code ở đây chỉ là dữ liệu kiểm thử.
          await ledgerService.recordSale(
            householdId,
            {
              sale_id: saleId,
              entry_date: sale.client_created_at.slice(0, 10),
              amount_vnd: amounts.totalVnd,
              sector_code: 'GOODS_DISTRIBUTION',
              payments: sale.payments.map((payment) => ({
                method: payment.method,
                amount_vnd: payment.amount_vnd,
              })),
            },
            client,
          );

          // Cố tình gây lỗi sau khi Ledger đã ghi
          throw new Error('TEST_ROLLBACK_SALES_LEDGER');
        },
      ),
    ).rejects.toThrow('TEST_ROLLBACK_SALES_LEDGER');

    expect(insertedSaleId).toBeDefined();

    // Kiểm tra đơn bán không được lưu lại
    const savedSales = await database.query(
      `SELECT id FROM sales
       WHERE client_op_id = $1`,
      [sale.client_op_id],
    );

    expect(savedSales.rows).toHaveLength(0);

    // Kiểm tra các bút toán Ledger cũng bị rollback
    const savedLedger = await database.query(
      `SELECT id FROM ledger_entry
       WHERE household_id = $1
         AND ref_id = $2
         AND ref_type IN ('SALE', 'SALE_PAYMENT')`,
      [householdId, insertedSaleId],
    );

    expect(savedLedger.rows).toHaveLength(0);
  }, 20000);

  it('Ghi doanh thu Ledger thành công và không ghi trùng', async () => {
    const sale = makeSale();
    const deviceId = `test-${randomUUID()}`;

    testOperationIds.push(sale.client_op_id);

    const ledgerService = new LedgerService(database);

    let postingCount = 0;

    const onAccepted = async (
      client: import('../../common/database').SqlClient,
      saleId: string,
    ) => {
      postingCount++;

      await ledgerService.recordSale(
        householdId,
        {
          sale_id: saleId,
          // Chỉ là dữ liệu thử nghiệm, chưa dùng cho API thật
          entry_date: sale.client_created_at.slice(0, 10),
          amount_vnd: amounts.totalVnd,
          sector_code: 'GOODS_DISTRIBUTION',
          payments: sale.payments.map((payment) => ({
            method: payment.method,
            amount_vnd: payment.amount_vnd,
          })),
        },
        client,
      );
    };

    // Tạo đơn và ghi Ledger thật
    const created = await repository.createSale(
      householdId,
      deviceId,
      sale,
      amounts,
      onAccepted,
    );

    expect(created.duplicate).toBe(false);
    expect(postingCount).toBe(1);

    // Kiểm tra bút toán doanh thu và tiền mặt
    const entries = await database.query<{
      ref_type: string;
      type: string;
      amount_vnd: string;
    }>(
      `SELECT ref_type, type, amount_vnd::text
       FROM ledger_entry
       WHERE household_id = $1
         AND ref_id = $2
       ORDER BY ref_type`,
      [householdId, created.sale_id],
    );

    expect(entries.rows).toHaveLength(2);

    expect(entries.rows).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          ref_type: 'SALE',
          type: 'REVENUE',
          amount_vnd: '90000',
        }),
        expect.objectContaining({
          ref_type: 'SALE_PAYMENT',
          type: 'CASH',
          amount_vnd: '90000',
        }),
      ]),
    );

    // Gửi lại cùng giao dịch
    const duplicate = await repository.createSale(
      householdId,
      deviceId,
      sale,
      amounts,
      onAccepted,
    );

    expect(duplicate.duplicate).toBe(true);
    expect(duplicate.sale_id).toBe(created.sale_id);

    // Gửi trùng không được ghi Ledger lần thứ hai
    expect(postingCount).toBe(1);
  }, 20000);

});
