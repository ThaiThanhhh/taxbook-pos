
import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';

import type { SqlClient } from '../../common/database';
import { LedgerService } from '../ledger/ledger.service';
import type { SalePosting } from '../ledger/sales-ledger.contract';
import type { SyncSaleDto } from './dto/sync-sales.dto';

// Mã ngành mà Ledger hiện hỗ trợ
export type SectorCode =
  | 'GOODS_DISTRIBUTION'
  | 'SERVICE'
  | 'PRODUCTION_TRANSPORT'
  | 'OTHER';

// Dữ liệu do backend xác định, không lấy trực tiếp từ Flutter
export interface SaleLedgerContext {
  householdId: string;
  entryDate: string;
  sectorCode: SectorCode;
}

@Injectable()
export class SalesLedgerAdapter {
  constructor(
    private readonly ledgerService: LedgerService,
  ) {}

  async recordAcceptedSale(
    client: SqlClient,
    saleId: string,
    sale: SyncSaleDto,
    totalVnd: number,
    context: SaleLedgerContext,
  ) {
    if (!context?.householdId?.trim()) {
      throw new BadRequestException(
        'Thiếu thông tin hộ kinh doanh',
      );
    }

    if (
      !context.entryDate ||
      !/^\d{4}-\d{2}-\d{2}$/.test(context.entryDate)
    ) {
      throw new BadRequestException(
        'Ngày ghi nhận doanh thu không hợp lệ',
      );
    }

    if (!context.sectorCode) {
      throw new BadRequestException(
        'Thiếu mã ngành kinh doanh',
      );
    }

    const posting: SalePosting = {
      sale_id: saleId,
      entry_date: context.entryDate,
      amount_vnd: totalVnd,
      sector_code: context.sectorCode,
      payments: sale.payments.map((payment) => ({
        method: payment.method,
        amount_vnd: payment.amount_vnd,
      })),
    };

    // Truyền client để dùng chung transaction với Sales
    return this.ledgerService.recordSale(
      context.householdId,
      posting,
      client,
    );
  }
}
