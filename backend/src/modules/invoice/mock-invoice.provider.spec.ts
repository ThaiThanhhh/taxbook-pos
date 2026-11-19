
import 'reflect-metadata';
import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';

import { MockInvoiceProvider } from './mock-invoice.provider';

describe('MockInvoiceProvider', () => {
  const provider = new MockInvoiceProvider();
  const previousMode = process.env.INVOICE_MOCK_MODE;

  const invoice = {
    invoice_id: 'invoice-001',
    sale_id: 'sale-001',
    amount_vnd: 90000,
  };

  afterEach(() => {
    if (previousMode === undefined) {
      delete process.env.INVOICE_MOCK_MODE;
    } else {
      process.env.INVOICE_MOCK_MODE = previousMode;
    }
  });

  it('Mặc định trả lỗi 503', async () => {
    delete process.env.INVOICE_MOCK_MODE;

    await expect(
      provider.issue(invoice),
    ).rejects.toThrow(ServiceUnavailableException);
  });

  it('Phát hành thành công ở chế độ demo', async () => {
    process.env.INVOICE_MOCK_MODE = 'SUCCESS';

    const result = await provider.issue(invoice);

    expect(result).toMatchObject({
      status: 'ISSUED',
      series: 'MOCK-DEMO',
    });

    expect(result.provider_ref).toMatch(/^MOCK-/);
  });

  it('Gửi lại cùng ID có mã tham chiếu ổn định', async () => {
    process.env.INVOICE_MOCK_MODE = 'SUCCESS';

    const first = await provider.issue(invoice);
    const second = await provider.issue(invoice);

    expect(second.number).toBe(first.number);
    expect(second.provider_ref).toBe(first.provider_ref);
  });

  it('Từ chối số tiền không hợp lệ', async () => {
    process.env.INVOICE_MOCK_MODE = 'SUCCESS';

    await expect(
      provider.issue({ ...invoice, amount_vnd: -1 }),
    ).rejects.toThrow(BadRequestException);
  });
});
