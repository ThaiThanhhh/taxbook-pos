import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';

import { randomUUID } from 'node:crypto';

import { SalesRepository } from './sales.repository';
import { SalesService } from './sales.service';
import {
  SalesLedgerAdapter,
  type SaleLedgerContext,
} from './sales-ledger.adapter';

import type { SyncSaleDto } from './dto/sync-sales.dto';

@Injectable()
export class SalesPostingService {
  constructor(
    private readonly salesService: SalesService,
    private readonly salesRepository: SalesRepository,
    private readonly ledgerAdapter: SalesLedgerAdapter,
  ) {}

  // Lưu đơn bán và ghi Ledger trong cùng transaction
  async saveAcceptedSale(
    deviceId: string,
    sale: SyncSaleDto,
    context: SaleLedgerContext,
  ) {
    // Kiểm tra thông tin hộ kinh doanh
    if (!context?.householdId?.trim()) {
      throw new BadRequestException(
        'Thiếu thông tin hộ kinh doanh',
      );
    }

    // Kiểm tra thiết bị bán hàng
    if (!deviceId?.trim()) {
      throw new BadRequestException(
        'Mã thiết bị không hợp lệ',
      );
    }

    // Backend tự tính tiền
    const amounts = this.salesService.calculateSaleTotal(sale);

    // Lưu Sales và gọi Ledger trong cùng transaction
    return this.salesRepository.createSale(
      context.householdId,
      deviceId,
      sale,
      {
        totalVnd: amounts.totalVnd,
        discountVnd: amounts.discountVnd,
      },
      async (client, saleId) => {
        await this.ledgerAdapter.recordAcceptedSale(
          client,
          saleId,
          sale,
          amounts.totalVnd,
          context,
        );
      },
    );
  }
  // Đồng bộ nhiều đơn và ghi Ledger cho từng đơn hợp lệ
  async syncAcceptedSalesBatch(
    householdId: string,
    deviceId: string,
    sales: SyncSaleDto[],
    resolveAccountingContext: (
      sale: SyncSaleDto,
    ) => Promise<
      Pick<SaleLedgerContext, 'entryDate' | 'sectorCode'>
    >,
  ) {
    if (!householdId?.trim()) {
      throw new BadRequestException(
        'Mã hộ kinh doanh không hợp lệ',
      );
    }

    if (!deviceId?.trim()) {
      throw new BadRequestException(
        'Mã thiết bị không hợp lệ',
      );
    }

    if (
      !Array.isArray(sales) ||
      sales.length < 1 ||
      sales.length > 200
    ) {
      throw new BadRequestException(
        'Lô phải có từ 1 đến 200 đơn hàng',
      );
    }

    if (typeof resolveAccountingContext !== 'function') {
      throw new Error(
        'Chưa có nguồn dữ liệu kế toán đáng tin cậy',
      );
    }

    // Xử lý theo thứ tự giao dịch trên thiết bị
    const orderedSales = [...sales].sort(
      (a, b) => a.local_seq - b.local_seq,
    );

    const results = [];

    for (const sale of orderedSales) {
      // Dữ liệu kế toán phải được backend xác định.
      // Nếu không lấy được thì dừng để tránh ghi sai.
      const accounting = await resolveAccountingContext(sale);

      if (
        !accounting?.entryDate ||
        !accounting?.sectorCode
      ) {
        throw new Error(
          'Thiếu ngày bán hoặc mã ngành từ backend',
        );
      }

      const context: SaleLedgerContext = {
        householdId,
        entryDate: accounting.entryDate,
        sectorCode: accounting.sectorCode,
      };

      try {
        // Lưu Sales và Ledger trong một transaction
        const saved = await this.saveAcceptedSale(
          deviceId,
          sale,
          context,
        );

        results.push({
          client_op_id: sale.client_op_id,
          ...saved,
        });
      } catch (error) {
        // Lỗi nghiệp vụ của một đơn không chặn đơn sau
        if (
          error instanceof BadRequestException ||
          error instanceof ConflictException
        ) {
          results.push({
            client_op_id: sale.client_op_id,
            status: 'REJECTED',
            duplicate: false,
            error: {
              error: {
                code:
                  error instanceof ConflictException
                    ? 'CONFLICT'
                    : 'VALIDATION_FAILED',
                message: error.message,
                trace_id: randomUUID(),
              },
            },
          });

          continue;
        }

        // Lỗi hệ thống cần được báo ra để thử lại
        throw error;
      }
    }

    return {
      results,
      server_time: new Date().toISOString(),
    };
  }

}
