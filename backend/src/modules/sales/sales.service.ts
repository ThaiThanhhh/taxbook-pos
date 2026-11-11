import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { SalesRepository } from './sales.repository';
import type { SyncSaleDto } from './dto/sync-sales.dto';

@Injectable()
export class SalesService {
  constructor(
    private readonly salesRepository: SalesRepository,
  ) {}

  // Tìm đơn hàng theo ID

  async findById(householdId: string, saleId: string) {
    const sale = await this.salesRepository.findById(
      householdId,
      saleId,
    );

    if (!sale) {
      throw new NotFoundException(
        'Không tìm thấy đơn hàng',
      );
    }

    return sale;
  }


  // Tính và kiểm tra tổng tiền giao dịch
  calculateSaleTotal(sale: SyncSaleDto) {
    let subtotalVnd = 0;

    for (const item of sale.items) {
      if (
        !Number.isSafeInteger(item.qty) ||
        item.qty <= 0 ||
        !Number.isSafeInteger(item.unit_price_vnd) ||
        item.unit_price_vnd < 0
      ) {
        throw new BadRequestException(
          'Số lượng hoặc đơn giá không hợp lệ',
        );
      }

      const lineTotal = item.qty * item.unit_price_vnd;

      if (
        !Number.isSafeInteger(lineTotal) ||
        !Number.isSafeInteger(subtotalVnd + lineTotal)
      ) {
        throw new BadRequestException(
          'Tổng tiền vượt giới hạn an toàn',
        );
      }

      subtotalVnd += lineTotal;
    }

    const discountVnd = sale.discount_vnd ?? 0;

    if (
      !Number.isSafeInteger(discountVnd) ||
      discountVnd < 0 ||
      discountVnd > subtotalVnd
    ) {
      throw new BadRequestException(
        'Số tiền giảm giá không hợp lệ',
      );
    }

    const totalVnd = subtotalVnd - discountVnd;

    let paidVnd = 0;

    for (const payment of sale.payments) {
      if (
        !Number.isSafeInteger(payment.amount_vnd) ||
        payment.amount_vnd < 0 ||
        !Number.isSafeInteger(
          paidVnd + payment.amount_vnd,
        )
      ) {
        throw new BadRequestException(
          'Số tiền thanh toán không hợp lệ',
        );
      }

      paidVnd += payment.amount_vnd;
    }

    if (paidVnd !== totalVnd) {
      throw new BadRequestException(
        'Tổng tiền thanh toán không khớp đơn hàng',
      );
    }

    return {
      subtotalVnd,
      discountVnd,
      totalVnd,
      paidVnd,
    };
  }

  // Tính tiền và lưu đơn bán theo hộ kinh doanh
  async saveSale(
    householdId: string,
    deviceId: string,
    sale: SyncSaleDto,
  ) {
    if (!householdId?.trim()) {
      throw new BadRequestException(
        'Mã hộ kinh doanh không hợp lệ',
      );
    }

    if (!deviceId?.trim()) {
      throw new BadRequestException(
        'Mã thiết bị không được để trống',
      );
    }

    const amounts = this.calculateSaleTotal(sale);

    return this.salesRepository.createSale(
      householdId,
      deviceId,
      sale,
      {
        totalVnd: amounts.totalVnd,
        discountVnd: amounts.discountVnd,
      },
    );
  }
  // Đồng bộ nhiều đơn bán từ một thiết bị
async syncSalesBatch(
  householdId: string,
  deviceId: string,
  sales: SyncSaleDto[],
)
   {
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
        'Mỗi lô phải có từ 1 đến 200 đơn hàng',
      );
    }

    // Xử lý theo thứ tự tạo đơn trên thiết bị
    const orderedSales = [...sales].sort(
      (a, b) => a.local_seq - b.local_seq,
    );

    const results = [];

    for (const sale of orderedSales) {
      try {
        const saved = await this.saveSale(
        householdId,
        deviceId,
        sale,
     );

        results.push({
          client_op_id: sale.client_op_id,
          ...saved,
        });
      } catch (error) {
        // Lỗi dữ liệu của một đơn không chặn đơn sau
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
                trace_id:randomUUID(),
              },
            },
          });

          continue;
        }

        // Lỗi hệ thống/database không được giả thành
        // lỗi dữ liệu của khách hàng
        throw error;
      }
    }

    return {
      results,
      server_time: new Date().toISOString(),
    };
  }

}
