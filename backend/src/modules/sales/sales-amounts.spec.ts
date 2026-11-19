
import { BadRequestException } from '@nestjs/common';
import { SalesService } from './sales.service';
import { SalesRepository } from './sales.repository';
import type { SyncSaleDto } from './dto/sync-sales.dto';

describe('Sales - Tính tiền giao dịch', () => {
  const service = new SalesService(
    {} as SalesRepository,
  );

  const validSale = {
    items: [
      {
        product_id: 'p-001',
        qty: 2,
        unit_price_vnd: 45000,
      },
    ],
    discount_vnd: 10000,
    payments: [
      {
        method: 'CASH',
        amount_vnd: 80000,
      },
    ],
  } as SyncSaleDto;

  it('Tính tổng tiền chính xác', () => {
    const result = service.calculateSaleTotal(validSale);

    expect(result.subtotalVnd).toBe(90000);
    expect(result.discountVnd).toBe(10000);
    expect(result.totalVnd).toBe(80000);
    expect(result.paidVnd).toBe(80000);
  });

  it('Từ chối thanh toán sai số tiền', () => {
    const invalidSale = {
      ...validSale,
      payments: [
        {
          method: 'CASH',
          amount_vnd: 70000,
        },
      ],
    } as SyncSaleDto;

    expect(() =>
      service.calculateSaleTotal(invalidSale),
    ).toThrow(BadRequestException);
  });

  it('Từ chối giảm giá lớn hơn tiền hàng', () => {
    const invalidSale = {
      ...validSale,
      discount_vnd: 100000,
    } as SyncSaleDto;

    expect(() =>
      service.calculateSaleTotal(invalidSale),
    ).toThrow(BadRequestException);
  });
});
