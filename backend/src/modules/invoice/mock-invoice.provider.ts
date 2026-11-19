
import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { createHash } from 'node:crypto';

export interface MockInvoiceRequest {
  invoice_id: string;
  sale_id: string;
  amount_vnd: number;
}

@Injectable()
export class MockInvoiceProvider {
  async issue(input: MockInvoiceRequest) {
    if (
      !input ||
      typeof input.invoice_id !== 'string' ||
      !input.invoice_id.trim() ||
      typeof input.sale_id !== 'string' ||
      !input.sale_id.trim() ||
      !Number.isSafeInteger(input.amount_vnd) ||
      input.amount_vnd <= 0
    ) {
      throw new BadRequestException(
        'Dữ liệu phát hành hóa đơn không hợp lệ',
      );
    }

    // Mặc định từ chối, chỉ bật thành công khi demo.
    if (process.env.INVOICE_MOCK_MODE !== 'SUCCESS') {
      throw new ServiceUnavailableException(
        'Mock invoice provider unavailable',
      );
    }

    const mockNumber = createHash('sha256')
      .update(input.invoice_id)
      .digest('hex')
      .slice(0, 24)
      .toUpperCase();

    return {
      status: 'ISSUED' as const,
      series: 'MOCK-DEMO',
      number: mockNumber,
      provider_ref: `MOCK-${mockNumber}`,
      issued_at: new Date().toISOString(),
    };
  }
}
