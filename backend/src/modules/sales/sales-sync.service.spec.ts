
import { jest } from '@jest/globals';
import { BadRequestException } from '@nestjs/common';

import { SalesService } from './sales.service';
import type { SalesRepository } from './sales.repository';
import type { SyncSaleDto } from './dto/sync-sales.dto';

describe('SalesService - saveSale', () => {
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
    discount_vnd: 0,
    payments: [
      {
        method: 'CASH',
        amount_vnd: 90000,
      },
    ],
  } as SyncSaleDto;

  function setup() {

const createSale = jest.fn(async (
  _householdId: string,
  _deviceId: string,
  _sale: SyncSaleDto,
  _amounts: {
    totalVnd: number;
    discountVnd: number;
  },
) => ({

      sale_id: 'sale-001',
      status: 'SYNCED',
      duplicate: false,
    }));

    const repository = {
      createSale,
    } as unknown as SalesRepository;

    return {
      service: new SalesService(repository),
      createSale,
    };
  }

  it('Tính tiền đúng trước khi lưu đơn', async () => {
    const { service, createSale } = setup();

    const result = await service.saveSale(
  'household-001',
  'dev-001',
  sale,
);


expect(createSale).toHaveBeenCalledWith(
  'household-001',
  'dev-001',
  sale,
  {
    totalVnd: 90000,
    discountVnd: 0,
  },
);


    expect(result.duplicate).toBe(false);
  });

  it('Không lưu đơn khi thanh toán sai', async () => {
    const { service, createSale } = setup();

    const invalidSale = {
      ...sale,
      payments: [
        {
          method: 'CASH',
          amount_vnd: 80000,
        },
      ],
    } as SyncSaleDto;

    await expect(
      service.saveSale(
  'household-001',
  'dev-001',
  invalidSale,
)
    ).rejects.toThrow(BadRequestException);

    expect(createSale).not.toHaveBeenCalled();
  });

  it('Giữ nguyên kết quả chống trùng từ Repository', async () => {
    const { service, createSale } = setup();

    createSale.mockResolvedValueOnce({
      sale_id: 'sale-old',
      status: 'SYNCED',
      duplicate: true,
    });

    const result = await service.saveSale(
  'household-001',
  'dev-001',
  sale,
);

    expect(result.sale_id).toBe('sale-old');
    expect(result.duplicate).toBe(true);
  });
});
