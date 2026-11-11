
import { jest } from '@jest/globals';
import { ConflictException } from '@nestjs/common';
import { SalesRepository } from './sales.repository';

import type { Database } from '../../common/database';
import type { SyncSaleDto } from './dto/sync-sales.dto';

describe('SalesRepository - createSale', () => {
  const sale = {
    client_op_id: 'b3c1d2e4-5f60-4a7b-9c8d-0e1f2a3b4c5d',
    local_seq: 1,
    client_created_at: '2026-11-02T05:12:44Z',
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
  } as unknown as SyncSaleDto;

  const amounts = {
    totalVnd: 90000,
    discountVnd: 0,
  };

  // Tạo database giả lập cho Unit Test
  function createMockRepository(
    handler: (
      sql: string,
    ) => Promise<{
      rows: Record<string, unknown>[];
    }>,
  ) {
    const query = jest.fn(
      async (sql: string, _values?: unknown[]) => {
        return handler(sql);
      },
    );

    const transaction = jest.fn(
      async (
        work: (client: {
          query: typeof query;
        }) => Promise<unknown>,
      ) => {
        return work({ query });
      },
    );

    const database = {
      transaction,
    } as unknown as Database;

    return {
      repository: new SalesRepository(database),
      query,
      transaction,
    };
  }

  it('Tạo đơn mới và lưu đủ 3 bảng', async () => {
    const { repository, query, transaction } =
      createMockRepository(async (sql) => {
        if (sql.includes('INSERT INTO sales')) {
          return {
            rows: [{ id: 'sale-001' }],
          };
        }

        return { rows: [] };
      });

   const result = await repository.createSale(
  'household-001',
  'dev-001',
  sale,
  amounts,
);

    expect(result).toEqual({
      sale_id: 'sale-001',
      status: 'SYNCED',
      duplicate: false,
    });

    expect(transaction).toHaveBeenCalledTimes(1);
    expect(query).toHaveBeenCalledTimes(3);
    // Kiểm tra household_id được truyền vào câu INSERT
expect(query.mock.calls[0][1]?.[0]).toBe(
  'household-001',
);

    const queries = query.mock.calls.map(
      ([sql]) => sql,
    );

    expect(queries[0]).toContain('INSERT INTO sales');
    expect(queries[1]).toContain('INSERT INTO sale_items');
    expect(queries[2]).toContain('INSERT INTO payments');
  });

  it('Không tạo thêm đơn khi gửi trùng client_op_id', async () => {
    const { repository, query } =
      createMockRepository(async (sql) => {
        if (sql.includes('INSERT INTO sales')) {
          return { rows: [] };
        }

        if (sql.includes('FROM sales')) {
          return {
            rows: [
              {
                id: 'sale-old',
                device_id: 'dev-001',
                local_seq: 1,
                status: 'SYNCED',
              },
            ],
          };
        }

        return { rows: [] };
      });

    const result = await repository.createSale(
  'household-001',
  'dev-001',
  sale,
  amounts,
);

    expect(result).toEqual({
      sale_id: 'sale-old',
      status: 'SYNCED',
      duplicate: true,
    });

    expect(query).toHaveBeenCalledTimes(2);
  });

  it('Từ chối mã giao dịch trùng nhưng khác thiết bị', async () => {
    const { repository } =
      createMockRepository(async (sql) => {
        if (sql.includes('INSERT INTO sales')) {
          return { rows: [] };
        }

        return {
          rows: [
            {
              id: 'sale-old',
              device_id: 'dev-other',
              local_seq: 1,
              status: 'SYNCED',
            },
          ],
        };
      });

    await expect(
  repository.createSale(
    'household-001',
    'dev-001',
    sale,
    amounts,
  ),
).rejects.toThrow(ConflictException);
  });

  it('Báo lỗi khi lưu thanh toán thất bại', async () => {
    const { repository, transaction } =
      createMockRepository(async (sql) => {
        if (sql.includes('INSERT INTO sales')) {
          return {
            rows: [{ id: 'sale-001' }],
          };
        }

        if (sql.includes('INSERT INTO payments')) {
          throw new Error('Lỗi lưu thanh toán');
        }

        return { rows: [] };
      });

    await expect(
  repository.createSale(
    'household-001',
    'dev-001',
    sale,
    amounts,
  ),
).rejects.toThrow('Lỗi lưu thanh toán');

    expect(transaction).toHaveBeenCalledTimes(1);
  });
});
