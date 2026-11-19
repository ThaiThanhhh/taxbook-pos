
import { Injectable } from '@nestjs/common';

import { InvoiceOutboxRepository } from './invoice-outbox.repository';
import { MockInvoiceProvider } from './mock-invoice.provider';

export type InvoiceWorkerResult =
  | { status: 'EMPTY' }
  | {
      status: 'ISSUED' | 'RETRY' | 'FAILED' | 'STALE';
      invoice_id: string;
    };

@Injectable()
export class InvoiceOutboxWorkerService {
  constructor(
    private readonly outbox: InvoiceOutboxRepository,
    private readonly provider: MockInvoiceProvider,
  ) {}

  async processNext(): Promise<InvoiceWorkerResult> {
    // Lấy công việc đến hạn và khóa bằng PostgreSQL.
    const job = await this.outbox.claimNext();

    if (!job) {
      return { status: 'EMPTY' };
    }

    let issued: Awaited<ReturnType<MockInvoiceProvider['issue']>>;

    try {
      const amount = Number(job.amount_vnd);

      if (!Number.isSafeInteger(amount) || amount <= 0) {
        throw new Error('Số tiền hóa đơn không hợp lệ');
      }

      // Dùng invoice_id cố định trong mọi lần retry.
      issued = await this.provider.issue({
        invoice_id: job.invoice_id,
        sale_id: job.sale_id,
        amount_vnd: amount,
      });
    } catch (error) {
      // Provider thất bại: ghi nhận RETRY hoặc FAILED.
      const reason =
        error instanceof Error
          ? error.message
          : 'Lỗi phát hành hóa đơn không xác định';

      const updated = await this.outbox.markFailure(
        job.id,
        job.attempts,
        reason,
      );

      const status =
        updated?.status === 'RETRY' ||
        updated?.status === 'FAILED'
          ? updated.status
          : 'STALE';

      return {
        status,
        invoice_id: job.invoice_id,
      };
    }

    // Không bắt lỗi DB ở đây: nếu transaction thất bại,
    // lease sẽ hết hạn và công việc được xử lý lại.
    const completed = await this.outbox.completeIssued(
      job.id,
      job.attempts,
      issued,
    );

    return {
      status: completed ? 'ISSUED' : 'STALE',
      invoice_id: job.invoice_id,
    };
  }
}
