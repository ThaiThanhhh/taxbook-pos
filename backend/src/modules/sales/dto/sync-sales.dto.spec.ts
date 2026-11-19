import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { SyncSalesRequestDto } from './sync-sales.dto';

describe('SyncSalesRequestDto', () => {
  // Dữ liệu đơn hàng hợp lệ để kiểm thử
  const validSale = {
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
  };

  it('Chấp nhận dữ liệu đơn hàng hợp lệ', async () => {
    const dto = plainToInstance(SyncSalesRequestDto, {
      device_id: 'dev-001',
      sales: [validSale],
    });

    const errors = await validate(dto);

    expect(errors).toHaveLength(0);
  });

  it('Từ chối sản phẩm có số lượng bằng 0', async () => {
    const dto = plainToInstance(SyncSalesRequestDto, {
      device_id: 'dev-001',
      sales: [
        {
          ...validSale,
          items: [
            {
              product_id: 'p-001',
              qty: 0,
              unit_price_vnd: 45000,
            },
          ],
        },
      ],
    });

    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(JSON.stringify(errors)).toContain('qty');
  });

  it('Từ chối lô có hơn 200 đơn hàng', async () => {
    const sales = Array.from(
      { length: 201 },
      (_, index) => ({
        ...validSale,
        local_seq: index + 1,
      }),
    );

    const dto = plainToInstance(SyncSalesRequestDto, {
      device_id: 'dev-001',
      sales,
    });

    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(JSON.stringify(errors)).toContain('sales');
  });
});
