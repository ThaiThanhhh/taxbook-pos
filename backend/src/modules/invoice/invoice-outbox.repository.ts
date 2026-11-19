
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { Database } from '../../common/database';

export type InvoiceOutboxStatus =
  | 'PENDING'
  | 'PROCESSING'
  | 'RETRY'
  | 'ISSUED'
  | 'FAILED';

export interface InvoiceOutboxRecord {
  id: string;
  household_id: string;
  sale_id: string;
  invoice_id: string;
  amount_vnd: string;
  status: InvoiceOutboxStatus;
  attempts: number;
  next_retry_at: Date | null;
  lease_until: Date | null;
  last_error: string | null;
  created_at: Date;
  updated_at: Date;
}

@Injectable()
export class InvoiceOutboxRepository {
  constructor(
    private readonly database: Database,
  ) {}

  // Đưa đơn bán đã đồng bộ vào hàng đợi hóa đơn.
  async enqueue(
    householdId: string,
    saleId: string,
  ): Promise<InvoiceOutboxRecord> {
    if (!householdId?.trim() || !saleId?.trim()) {
      throw new BadRequestException(
        'Thiếu mã hộ kinh doanh hoặc đơn bán',
      );
    }

    return this.database.transaction(async (client) => {
      // Khóa đơn bán để xử lý an toàn khi có
      // nhiều yêu cầu đồng thời.
      const saleResult = await client.query<{
        id: string;
        total_vnd: string;
        status: string;
      }>(
        `SELECT
           id,
           total_vnd::text AS total_vnd,
           status
         FROM sales
         WHERE id = $1 AND household_id = $2
         FOR UPDATE`,
        [saleId, householdId],
      );

      const sale = saleResult.rows[0];

      if (!sale) {
        throw new NotFoundException(
          'Không tìm thấy đơn bán thuộc hộ kinh doanh',
        );
      }

      // Nếu đã có trong hàng đợi, trả lại bản ghi cũ.
      // Không tạo invoice_id mới khi gửi lại.
      const existing = await client.query<InvoiceOutboxRecord>(
        `SELECT *
         FROM invoice_outbox
         WHERE sale_id = $1
         LIMIT 1`,
        [saleId],
      );

      if (existing.rows.length) {
        const previous = existing.rows[0];

        if (previous.household_id !== householdId) {
          throw new ConflictException(
            'Dữ liệu hộ kinh doanh không nhất quán',
          );
        }

        return previous;
      }

      if (sale.status !== 'SYNCED') {
        throw new ConflictException(
          'Trạng thái đơn bán chưa cho phép phát hành hóa đơn',
        );
      }

      // Không đưa vào hàng đợi nếu đã có hóa đơn.
      const issued = await client.query(
        `SELECT id
         FROM invoices
         WHERE sale_id = $1
         LIMIT 1`,
        [saleId],
      );

      if (issued.rows.length) {
        throw new ConflictException(
          'Đơn bán đã có hóa đơn',
        );
      }

      // Giá trị tiền phải an toàn khi sử dụng trong JS.
      const amount = Number(sale.total_vnd);

      if (!Number.isSafeInteger(amount) || amount <= 0) {
        throw new ConflictException(
          'Số tiền đơn bán không hợp lệ',
        );
      }

      // Tạo yêu cầu phát hành lần đầu.
      const result = await client.query<InvoiceOutboxRecord>(
        `INSERT INTO invoice_outbox (
           household_id,
           sale_id,
           amount_vnd,
           status
         )
         VALUES ($1, $2, $3, 'PENDING')
         RETURNING *`,
        [householdId, saleId, amount.toString()],
      );

      return result.rows[0];
    });
  }

  // Lấy một yêu cầu phát hành đến hạn xử lý.
  async claimNext(): Promise<InvoiceOutboxRecord | null> {
    const result =
      await this.database.query<InvoiceOutboxRecord>(
        `WITH next_job AS (
          SELECT id
          FROM invoice_outbox
          WHERE (
            status IN ('PENDING', 'RETRY')
            AND next_retry_at <= NOW()
          )
          OR (
            status = 'PROCESSING'
            AND lease_until IS NOT NULL
            AND lease_until <= NOW()
          )
          ORDER BY
            COALESCE(next_retry_at, lease_until),
            created_at,
            id
          FOR UPDATE SKIP LOCKED
          LIMIT 1
        )
        UPDATE invoice_outbox AS o
        SET
          status = 'PROCESSING',
          attempts = o.attempts + 1,
          lease_until = NOW() + INTERVAL '5 minutes',
          next_retry_at = NULL,
          updated_at = NOW()
        FROM next_job
        WHERE o.id = next_job.id
        RETURNING o.*`,
      );

    return result.rows[0] ?? null;
  }

  // Ghi nhận một lần phát hành thất bại.
  async markFailure(
    jobId: string,
    attempt: number,
    reason: string,
  ): Promise<InvoiceOutboxRecord | null> {
    if (
      !jobId?.trim() ||
      !Number.isInteger(attempt) ||
      attempt < 1 ||
      !reason?.trim()
    ) {
      throw new BadRequestException(
        'Thông tin xử lý hóa đơn không hợp lệ',
      );
    }

    const result =
      await this.database.query<InvoiceOutboxRecord>(
        `UPDATE invoice_outbox
         SET
           status = CASE
             WHEN attempts >= 5 THEN 'FAILED'
             ELSE 'RETRY'
           END,
           next_retry_at = CASE
             WHEN attempts >= 5 THEN NULL
             ELSE NOW() +
               (LEAST(300, attempts * 30) *
                INTERVAL '1 second')
           END,
           lease_until = NULL,
           last_error = $3,
           updated_at = NOW()
         WHERE id = $1
           AND status = 'PROCESSING'
           AND attempts = $2
           AND lease_until > NOW()
         RETURNING *`,
        [
          jobId,
          attempt,
          reason.trim().slice(0, 500),
        ],
      );

    // null: công việc đã được worker khác tiếp nhận
    // hoặc phiên xử lý đã hết hạn.
    return result.rows[0] ?? null;
  }

  // Lưu hóa đơn và hoàn tất công việc trong cùng transaction.
  async completeIssued(
    jobId: string,
    attempt: number,
    issued: {
      series: string;
      number: string;
      provider_ref: string;
      issued_at: string;
    },
  ): Promise<InvoiceOutboxRecord | null> {
    if (
      !jobId?.trim() ||
      !Number.isInteger(attempt) ||
      attempt < 1 ||
      !issued?.series?.trim() ||
      !issued?.number?.trim() ||
      !issued?.provider_ref?.trim() ||
      !issued?.issued_at ||
      !Number.isFinite(Date.parse(issued.issued_at))
    ) {
      throw new BadRequestException(
        'Kết quả phát hành hóa đơn không hợp lệ',
      );
    }

    return this.database.transaction(async (client) => {
      const reference = await client.query<{
        sale_id: string;
        household_id: string;
      }>(
        `SELECT sale_id, household_id
         FROM invoice_outbox
         WHERE id = $1`,
        [jobId],
      );

      const ref = reference.rows[0];
      if (!ref) return null;

      // Thống nhất thứ tự khóa: sales trước, outbox sau.
      const sale = await client.query(
        `SELECT id FROM sales
         WHERE id = $1 AND household_id = $2
         FOR UPDATE`,
        [ref.sale_id, ref.household_id],
      );

      if (!sale.rows.length) {
        throw new ConflictException(
          'Đơn bán không còn hợp lệ',
        );
      }

      // Chỉ worker đang giữ lease hợp lệ được hoàn tất.
      const active = await client.query<InvoiceOutboxRecord>(
        `SELECT *
         FROM invoice_outbox
         WHERE id = $1
           AND status = 'PROCESSING'
           AND attempts = $2
           AND lease_until > NOW()
         FOR UPDATE`,
        [jobId, attempt],
      );

      const job = active.rows[0];
      if (!job) return null;

      const existing = await client.query<{
        id: string;
        status: string;
        series: string;
        number: string;
        provider_ref: string | null;
      }>(
        `SELECT id, status, series, number, provider_ref
         FROM invoices
         WHERE sale_id = $1
         LIMIT 1`,
        [job.sale_id],
      );

      const previous = existing.rows[0];

      if (previous) {
        if (
          previous.id !== job.invoice_id ||
          previous.status !== 'ISSUED' ||
          previous.series !== issued.series ||
          previous.number !== issued.number ||
          previous.provider_ref !== issued.provider_ref
        ) {
          throw new ConflictException(
            'Đơn bán đã có hóa đơn không khớp',
          );
        }
      } else {
        await client.query(
          `INSERT INTO invoices (
            id, sale_id, series, number,
            status, provider_ref, issued_at,
            attempts, last_error
          )
          VALUES (
            $1, $2, $3, $4,
            'ISSUED', $5, $6, $7, NULL
          )`,
          [
            job.invoice_id,
            job.sale_id,
            issued.series,
            issued.number,
            issued.provider_ref,
            issued.issued_at,
            attempt,
          ],
        );
      }

      const result = await client.query<InvoiceOutboxRecord>(
        `UPDATE invoice_outbox
         SET
           status = 'ISSUED',
           lease_until = NULL,
           next_retry_at = NULL,
           last_error = NULL,
           updated_at = NOW()
         WHERE id = $1
           AND status = 'PROCESSING'
           AND attempts = $2
           AND lease_until > NOW()
         RETURNING *`,
        [jobId, attempt],
      );

      if (!result.rows.length) {
        // Transaction rollback, không để hóa đơn được
        // lưu mà outbox vẫn chưa hoàn tất.
        throw new ConflictException(
          'Phiên xử lý đã hết hạn',
        );
      }

      return result.rows[0];
    });
  }
}
