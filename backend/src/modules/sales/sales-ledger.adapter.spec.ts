
import 'reflect-metadata';

import { jest } from '@jest/globals';
import { BadRequestException } from '@nestjs/common';

import {
  SalesLedgerAdapter,
  type SaleLedgerContext,
} from './sales-ledger.adapter';

import type { LedgerService } from '../ledger/ledger.service';
import type { SalePosting } from '../ledger/sales-ledger.contract';
import type { SqlClient } from '../../common/database';
import type { SyncSaleDto } from './dto/sync-sales.dto';

describe('SalesLedgerAdapter', () => {
  const sale = {
    payments: [
      {
        method: 'CASH',
        amount_vnd: 90000,
      },
    ],
  } as SyncSaleDto;

  const context: SaleLedgerContext = {
    householdId: 'household-001',
    entryDate: '2026-11-02',
    sectorCode: 'GOODS_DISTRIBUTION',
  };

  // Kết nối giả lập, không truy cập PostgreSQL
  const client = {} as SqlClient;

  function setup() {
    const recordSale = jest.fn<
      (
        household: string,
        posting: SalePosting,
        transaction?: SqlClient,
      ) => Promise<{ duplicate: boolean }>
    >();

    recordSale.mockResolvedValue({
      duplicate: false,
    });

    const ledgerMock = {
      recordSale,
    } as unknown as LedgerService;

    return {
      adapter: new SalesLedgerAdapter(ledgerMock),
      recordSale,
    };
  }

  it('Truyền đúng dữ liệu Sales sang Ledger', async () => {
    const { adapter, recordSale } = setup();

    const result = await adapter.recordAcceptedSale(
      client,
      'sale-001',
      sale,
      90000,
      context,
    );

    expect(result.duplicate).toBe(false);

    expect(recordSale).toHaveBeenCalledWith(
      'household-001',
      {
        sale_id: 'sale-001',
        entry_date: '2026-11-02',
        amount_vnd: 90000,
        sector_code: 'GOODS_DISTRIBUTION',
        payments: [
          {
            method: 'CASH',
            amount_vnd: 90000,
          },
        ],
      },
      client,
    );
  });

  it('Từ chối khi thiếu hộ kinh doanh', async () => {
    const { adapter, recordSale } = setup();

    await expect(
      adapter.recordAcceptedSale(
        client,
        'sale-001',
        sale,
        90000,
        {
          ...context,
          householdId: '',
        },
      ),
    ).rejects.toThrow(BadRequestException);

    expect(recordSale).not.toHaveBeenCalled();
  });

  it('Báo lỗi khi Ledger ghi doanh thu thất bại', async () => {
    const { adapter, recordSale } = setup();

    recordSale.mockRejectedValue(
      new Error('Ledger unavailable'),
    );

    await expect(
      adapter.recordAcceptedSale(
        client,
        'sale-001',
        sale,
        90000,
        context,
      ),
    ).rejects.toThrow('Ledger unavailable');
  });
});
