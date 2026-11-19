
import 'reflect-metadata';

import { jest } from '@jest/globals';
import { BadRequestException } from '@nestjs/common';

import { SalesPostingService } from './sales-posting.service';
import { SalesService } from './sales.service';
import { PaymentMethod } from './dto/sync-sales.dto';

import type { SalesRepository } from './sales.repository';
import type { SalesLedgerAdapter } from './sales-ledger.adapter';
import type { SaleLedgerContext } from './sales-ledger.adapter';
import type { SyncSaleDto } from './dto/sync-sales.dto';
import type { SqlClient } from '../../common/database';

describe('SalesPostingService', () => {
  const context: SaleLedgerContext = {
    householdId: 'household-001',
    entryDate: '2026-11-02',
    sectorCode: 'GOODS_DISTRIBUTION',
  };

  const sale: SyncSaleDto = {
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
        method: PaymentMethod.CASH,
        amount_vnd: 90000,
      },
    ],
  };

  function setup() {
    // Giả lập kết nối PostgreSQL đang chạy transaction
    const client = {
      query: jest.fn(async () => ({ rows: [] })),
    } as unknown as SqlClient;

    // Giả lập Adapter ghi Ledger
    const recordAcceptedSale = jest.fn(
      async (
        _client: SqlClient,
        _saleId: string,
        _sale: SyncSaleDto,
        _totalVnd: number,
        _context: SaleLedgerContext,
      ) => ({ duplicate: false }),
    );

    // Giả lập Repository lưu đơn bán
    const createSale = jest.fn(
      async (
        _householdId: string,
        _deviceId: string,
        _sale: SyncSaleDto,
        _amounts: {
          totalVnd: number;
          discountVnd: number;
        },
        onAccepted?: (
          client: SqlClient,
          saleId: string,
        ) => Promise<void>,
      ) => {
        if (onAccepted) {
          await onAccepted(client, 'sale-001');
        }

        return {
          sale_id: 'sale-001',
          status: 'SYNCED',
          duplicate: false,
        };
      },
    );

    const repository = {
      createSale,
    } as unknown as SalesRepository;

    const adapter = {
      recordAcceptedSale,
    } as unknown as SalesLedgerAdapter;

    const salesService = new SalesService(repository);

    const postingService = new SalesPostingService(
      salesService,
      repository,
      adapter,
    );

    return {
      postingService,
      createSale,
      recordAcceptedSale,
      client,
    };
  }

  it('Lưu Sales và gọi Ledger đúng transaction', async () => {
    const {
      postingService,
      createSale,
      recordAcceptedSale,
      client,
    } = setup();

    const result = await postingService.saveAcceptedSale(
      'dev-001',
      sale,
      context,
    );

    expect(result.sale_id).toBe('sale-001');
    expect(result.duplicate).toBe(false);

    expect(createSale).toHaveBeenCalledWith(
      'household-001',
      'dev-001',
      sale,
      {
        totalVnd: 90000,
        discountVnd: 0,
      },
      expect.any(Function),
    );

    expect(recordAcceptedSale).toHaveBeenCalledWith(
      client,
      'sale-001',
      sale,
      90000,
      context,
    );
  });

  it('Không lưu đơn khi thanh toán sai', async () => {
    const {
      postingService,
      createSale,
      recordAcceptedSale,
    } = setup();

    const invalidSale: SyncSaleDto = {
      ...sale,
      payments: [
        {
          method: PaymentMethod.CASH,
          amount_vnd: 80000,
        },
      ],
    };

    await expect(
      postingService.saveAcceptedSale(
        'dev-001',
        invalidSale,
        context,
      ),
    ).rejects.toThrow(BadRequestException);

    expect(createSale).not.toHaveBeenCalled();
    expect(recordAcceptedSale).not.toHaveBeenCalled();
  });

  it('Chuyển tiếp lỗi khi Ledger thất bại', async () => {
    const {
      postingService,
      recordAcceptedSale,
    } = setup();

    recordAcceptedSale.mockRejectedValueOnce(
      new Error('Ledger unavailable'),
    );

    await expect(
      postingService.saveAcceptedSale(
        'dev-001',
        sale,
        context,
      ),
    ).rejects.toThrow('Ledger unavailable');
  });
});
