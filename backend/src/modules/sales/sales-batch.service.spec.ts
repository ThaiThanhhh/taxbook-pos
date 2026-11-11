
import { jest } from '@jest/globals';
import { BadRequestException } from '@nestjs/common';

import { SalesService } from './sales.service';
import type { SalesRepository } from './sales.repository';
import type { SyncSaleDto } from './dto/sync-sales.dto';

describe('SalesService - syncSalesBatch', () => {
  // Tạo đơn bán giả lập
  function makeSale(localSeq: number): SyncSaleDto {
    return {
      client_op_id: `00000000-0000-4000-8000-${String(
        localSeq,
      ).padStart(12, '0')}`,
      local_seq: localSeq,
      client_created_at: '2026-11-02T05:12:44Z',
      items: [
        {
          product_id: 'p-001',
          qty: 2,
          unit_price_vnd: 45000,
        },
      ],
      discount_vnd: 0,
      payments: [
        {
          method: 'CASH',
          amount_vnd: 90000,
        },
      ],
    } as SyncSaleDto;
  }

  // Repository giả, không kết nối PostgreSQL
  function setup(
    handler?: (
      sale: SyncSaleDto,
    ) => Promise<{
      sale_id: string;
      status: string;
      duplicate: boolean;
    }>,
  ) {
    const processed: number[] = [];


const createSale = jest.fn(
  async (
    _householdId: string,
    _deviceId: string,
    sale: SyncSaleDto,
    _amounts: {
      totalVnd: number;
      discountVnd: number;
    },
  ) => {

        processed.push(sale.local_seq);

        if (handler) {
          return handler(sale);
        }

        return {
          sale_id: `sale-${sale.local_seq}`,
          status: 'SYNCED',
          duplicate: false,
        };
      },
    );

    const repository = {
      createSale,
    } as unknown as SalesRepository;

    return {
      service: new SalesService(repository),
      createSale,
      processed,
    };
  }

  it('Xử lý các đơn theo local_seq tăng dần', async () => {
    const { service, processed, createSale } = setup();

    const sales = [
      makeSale(3),
      makeSale(1),
      makeSale(2),
    ];

    const result = await service.syncSalesBatch(
  'household-001',
  'dev-001',
  sales,
);

    expect(processed).toEqual([1, 2, 3]);
    expect(result.results).toHaveLength(3);

    expect(
      result.results.map((item) => item.status),
    ).toEqual(['SYNCED', 'SYNCED', 'SYNCED']);

    expect(createSale).toHaveBeenCalledTimes(3);

    // Không làm thay đổi mảng gốc Flutter gửi
    expect(sales.map((s) => s.local_seq)).toEqual([
      3, 1, 2,
    ]);
  });

  it('Một đơn sai tiền không chặn đơn tiếp theo', async () => {
    const { service, processed } = setup();

    const invalidSale = {
      ...makeSale(2),
      payments: [
        {
          method: 'CASH',
          amount_vnd: 80000,
        },
      ],
    } as SyncSaleDto;

    const result = await service.syncSalesBatch(
  'household-001',
  'dev-001',
  [
    makeSale(1),
    invalidSale,
    makeSale(3),
  ],
);

    expect(result.results).toHaveLength(3);

    expect(result.results[0].status).toBe('SYNCED');
    expect(result.results[1].status).toBe('REJECTED');
    expect(result.results[2].status).toBe('SYNCED');

    expect(
      JSON.stringify(result.results[1]),
    ).toContain('VALIDATION_FAILED');

    // Đơn lỗi không được gửi xuống Repository
    expect(processed).toEqual([1, 3]);
  });

  it('Báo lỗi hệ thống khi database thất bại', async () => {
    const { service, processed } = setup(
      async (sale) => {
        if (sale.local_seq === 2) {
          throw new Error('Database unavailable');
        }

        return {
          sale_id: `sale-${sale.local_seq}`,
          status: 'SYNCED',
          duplicate: false,
        };
      },
    );


await expect(
  service.syncSalesBatch(
    'household-001',
    'dev-001',
    [
      makeSale(1),
      makeSale(2),
      makeSale(3),
    ],
  ),
).rejects.toThrow('Database unavailable');


    // Dừng khi gặp lỗi hệ thống
    expect(processed).toEqual([1, 2]);
  });

  it('Từ chối lô rỗng, quá 200 đơn và thiết bị trống', async () => {
    const { service, createSale } = setup();


// Trường hợp 1: Lô rỗng
await expect(
  service.syncSalesBatch(
    'household-001',
    'dev-001',
    [],
  ),
).rejects.toThrow(BadRequestException);

const tooManySales = Array.from(
  { length: 201 },
  (_, index) => makeSale(index + 1),
);

// Trường hợp 2: Quá 200 đơn
await expect(
  service.syncSalesBatch(
    'household-001',
    'dev-001',
    tooManySales,
  ),
).rejects.toThrow(BadRequestException);

// Trường hợp 3: Mã thiết bị trống
await expect(
  service.syncSalesBatch(
    'household-001',
    '  ',
    [makeSale(1)],
  ),
).rejects.toThrow(BadRequestException);

expect(createSale).not.toHaveBeenCalled();

  });
});
