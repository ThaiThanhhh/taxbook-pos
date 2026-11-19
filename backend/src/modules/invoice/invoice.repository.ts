
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { Database } from '../../common/database';

export type InvoiceStatus =
  | 'ISSUED'
  | 'SENT'
  | 'REJECTED'
  | 'CANCELED';

export type InvoiceRecord = {
  id: string;
  sale_id: string;
  series: string;
  number: string;
  status: InvoiceStatus;
  provider_ref: string | null;
  issued_at: Date | null;
  attempts: number;
  last_error: string | null;
  created_at: Date;
};
export interface IssuedInvoiceInput {
  id: string;
  sale_id: string;
  series: string;
  number: string;
  provider_ref: string;
  issued_at: string;
}
@Injectable()
export class InvoiceRepository {
  constructor(
    private readonly database: Database,
  ) {}

  // Tìm hóa đơn theo đơn bán và hộ kinh doanh
  async findBySale(
    householdId: string,
    saleId: string,
  ): Promise<InvoiceRecord | null> {
    if (!householdId?.trim() || !saleId?.trim()) {
      throw new BadRequestException(
        'Thiếu mã hộ kinh doanh hoặc đơn bán',
      );
    }

    const result = await this.database.query<InvoiceRecord>(
      `SELECT
        i.id,
        i.sale_id,
        i.series,
        i.number,
        i.status,
        i.provider_ref,
        i.issued_at,
        i.attempts,
        i.last_error,
        i.created_at
      FROM invoices i
      INNER JOIN sales s
        ON s.id = i.sale_id
      WHERE s.household_id = $1
        AND i.sale_id = $2
      ORDER BY i.created_at DESC, i.id DESC
      LIMIT 1`,
      [householdId, saleId],
    );

    return result.rows[0] ?? null;
  }

  // Lưu hóa đơn đã được Mock Provider phát hành
  async saveIssued(
    householdId: string,
    input: IssuedInvoiceInput,
  ): Promise<InvoiceRecord> {
    if (
      !householdId?.trim() ||
      !input ||
      !input.id?.trim() ||
      !input.sale_id?.trim() ||
      !input.series?.trim() ||
      !input.number?.trim() ||
      !input.provider_ref?.trim() ||
      !input.issued_at ||
      !Number.isFinite(Date.parse(input.issued_at))
    ) {
      throw new BadRequestException(
        'Thông tin hóa đơn không hợp lệ',
      );
    }

    return this.database.transaction(async (client) => {
      // Khóa đơn bán để tránh hai yêu cầu đồng thời
      // tạo nhiều hóa đơn cho cùng một đơn.
      const sale = await client.query(
        `SELECT id
         FROM sales
         WHERE id = $1 AND household_id = $2
         FOR UPDATE`,
        [input.sale_id, householdId],
      );

      if (!sale.rows.length) {
        throw new NotFoundException(
          'Không tìm thấy đơn bán thuộc hộ kinh doanh',
        );
      }

      // Nếu hóa đơn đã được lưu, kiểm tra tính nhất quán.
      const existing = await client.query<InvoiceRecord>(
        `SELECT *
         FROM invoices
         WHERE sale_id = $1
         ORDER BY created_at DESC, id DESC
         LIMIT 1`,
        [input.sale_id],
      );

      if (existing.rows.length) {
        const previous = existing.rows[0];

        if (
          previous.id === input.id &&
          previous.series === input.series &&
          previous.number === input.number &&
          previous.provider_ref === input.provider_ref
        ) {
          // Yêu cầu lặp lại: không tạo thêm hóa đơn.
          return previous;
        }

        throw new ConflictException(
          'Đơn bán đã có hóa đơn khác',
        );
      }

      const result = await client.query<InvoiceRecord>(
        `INSERT INTO invoices (
          id,
          sale_id,
          series,
          number,
          status,
          provider_ref,
          issued_at,
          attempts,
          last_error
        )
        VALUES (
          $1, $2, $3, $4,
          'ISSUED', $5, $6, 1, NULL
        )
        RETURNING *`,
        [
          input.id,
          input.sale_id,
          input.series,
          input.number,
          input.provider_ref,
          input.issued_at,
        ],
      );

      return result.rows[0];
    });
  }

}
