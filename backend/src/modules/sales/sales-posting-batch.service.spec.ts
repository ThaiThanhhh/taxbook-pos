
import 'reflect-metadata';

import { jest } from '@jest/globals';
import { BadRequestException } from '@nestjs/common';

import { SalesPostingService } from './sales-posting.service';
import { SalesService } from './sales.service';
import { PaymentMethod } from './dto/sync-sales.dto';

import type { SalesRepository } from './sales.repository';
import type {
  SalesLedgerAdapter,
  SaleLedgerContext,
} from './sales-ledger.adapter';
import type { SyncSaleDto } from './dto/sync-sales.dto';
import type { SqlClient } from '../../common/database';

describe('SalesPostingService - syncAcceptedSalesBatch', () => {
  // Dữ liệu đơn hàng dùng trong kiểm thử
  function makeSale(localSeq: number): SyncSaleDto {
    return {
      client_op_id:
        `00000000-0000-4000-8000-${String(localSeq).padStart(12, '0')}`,
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
          method: PaymentMethod.CASH,
          amount_vnd: 90000,
        },
      ],
    };
  }

  // Giả lập thông tin kế toán do backend cung cấp
  const resolveAccountingContext = async (
    _sale: SyncSaleDto,
  ): Promise<
    Pick<SaleLedgerContext, 'entryDate' | 'sectorCode'>
  > => ({
    entryDate: '2026-11-02',
    sectorCode: 'GOODS_DISTRIBUTION',
  });

  function setup() {
    const client = {
      query: jest.fn(async () => ({ rows: [] })),
    } as unknown as SqlClient;

    // Mock Adapter ghi Ledger
    const recordAcceptedSale = jest.fn(
      async (
        _client: SqlClient,
        _saleId: string,
        _sale: SyncSaleDto,
        _totalVnd: number,
        _context: SaleLedgerContext,
      ) => ({ duplicate: false }),
    );

    // Mock Repository lưu Sales
    const createSale = jest.fn(
      async (
        _householdId: string,
        _deviceId: string,
        sale: SyncSaleDto,
        _amounts: {
          totalVnd: number;
          discountVnd: number;
        },
        onAccepted?: (
          client: SqlClient,
          saleId: string,
        ) => Promise<void>,
      ) => {
        const saleId = `sale-${sale.local_seq}`;

        if (onAccepted) {
          await onAccepted(client, saleId);
        }

        return {
          sale_id: saleId,
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
    };
  }

  it('Xử lý đúng thứ tự và ghi Ledger cho từng đơn', async () => {
    const {
      postingService,
      createSale,
      recordAcceptedSale,
    } = setup();

    const result =
      await postingService.syncAcceptedSalesBatch(
        'household-001',
        'dev-001',
        [makeSale(3), makeSale(1), makeSale(2)],
        resolveAccountingContext,
      );

    expect(result.results).toHaveLength(3);

    // Sales phải được xử lý theo thứ tự 1, 2, 3
    expect(
      createSale.mock.calls.map(
        (call) => call[2].local_seq,
      ),
    ).toEqual([1, 2, 3]);

    // Mỗi đơn hợp lệ được gửi sang Ledger
    expect(recordAcceptedSale).toHaveBeenCalledTimes(3);

    expect(
      result.results.map((item) => item.status),
    ).toEqual(['SYNCED', 'SYNCED', 'SYNCED']);
  });

  it('Đơn sai tiền không chặn các đơn còn lại', async () => {
    const {
      postingService,
      createSale,
      recordAcceptedSale,
    } = setup();

    const invalidSale = {
      ...makeSale(2),
      payments: [
        {
          method: PaymentMethod.CASH,
          amount_vnd: 80000,
        },
      ],
    };

    const result =
      await postingService.syncAcceptedSalesBatch(
        'household-001',
        'dev-001',
        [makeSale(1), invalidSale, makeSale(3)],
        resolveAccountingContext,
      );

    expect(
      result.results.map((item) => item.status),
    ).toEqual(['SYNCED', 'REJECTED', 'SYNCED']);

    // Chỉ 2 đơn hợp lệ được lưu
    expect(createSale).toHaveBeenCalledTimes(2);
    expect(recordAcceptedSale).toHaveBeenCalledTimes(2);
  });

  it('Không ghi đơn khi thiếu dữ liệu kế toán', async () => {
    const { postingService, createSale } = setup();

    await expect(
      postingService.syncAcceptedSalesBatch(
        'household-001',
        'dev-001',
        [makeSale(1)],
        async () => ({
          entryDate: '',
          sectorCode: 'GOODS_DISTRIBUTION',
        }),
      ),
    ).rejects.toThrow(
      'Thiếu ngày bán hoặc mã ngành từ backend',
    );

    expect(createSale).not.toHaveBeenCalled();
  });

  it('Chuyển tiếp lỗi nếu Ledger thất bại', async () => {
    const {
      postingService,
      recordAcceptedSale,
    } = setup();

    recordAcceptedSale.mockRejectedValueOnce(
      new Error('Ledger unavailable'),
    );

    await expect(
      postingService.syncAcceptedSalesBatch(
        'household-001',
        'dev-001',
        [makeSale(1)],
        resolveAccountingContext,
      ),
    ).rejects.toThrow('Ledger unavailable');
  });

  it('Từ chối lô không hợp lệ', async () => {
    const { postingService, createSale } = setup();

    await expect(
      postingService.syncAcceptedSalesBatch(
        'household-001',
        'dev-001',
        [],
        resolveAccountingContext,
      ),
    ).rejects.toThrow(BadRequestException);

    expect(createSale).not.toHaveBeenCalled();
  });
});
