
import 'reflect-metadata';

import { jest } from '@jest/globals';
import { BadRequestException } from '@nestjs/common';

import { Database } from '../../common/database';
import {
  InvoiceRepository,
  type InvoiceRecord,
} from './invoice.repository';

describe('InvoiceRepository - findBySale', () => {
  const query = jest.fn<
    (
      sql: string,
      values?: unknown[],
    ) => Promise<{ rows: InvoiceRecord[] }>
  >();

  const repository = new InvoiceRepository({
    query,
  } as unknown as Database);

  beforeEach(() => {
    query.mockReset();
  });

  it('Lấy hóa đơn thuộc đúng hộ kinh doanh', async () => {
    const invoice: InvoiceRecord = {
      id: 'invoice-001',
      sale_id: 'sale-001',
      series: 'MOCK-DEMO',
      number: '000001',
      status: 'ISSUED',
      provider_ref: 'MOCK-000001',
      issued_at: new Date('2026-11-19T00:00:00Z'),
      attempts: 1,
      last_error: null,
      created_at: new Date('2026-11-19T00:00:00Z'),
    };

    query.mockResolvedValue({
      rows: [invoice],
    });

    const result = await repository.findBySale(
      'household-001',
      'sale-001',
    );

    expect(result).toEqual(invoice);

    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('s.household_id = $1'),
      ['household-001', 'sale-001'],
    );
  });

  it('Không tìm thấy hóa đơn thì trả null', async () => {
    query.mockResolvedValue({ rows: [] });

    const result = await repository.findBySale(
      'household-002',
      'sale-001',
    );

    expect(result).toBeNull();
  });

  it('Từ chối householdId rỗng', async () => {
    await expect(
      repository.findBySale('', 'sale-001'),
    ).rejects.toThrow(BadRequestException);

    expect(query).not.toHaveBeenCalled();
  });

  it('Từ chối saleId rỗng', async () => {
    await expect(
      repository.findBySale('household-001', ''),
    ).rejects.toThrow(BadRequestException);

    expect(query).not.toHaveBeenCalled();
  });

describe('InvoiceRepository - saveIssued', () => {
  const query = jest.fn<
    (sql: string, values?: unknown[]) =>
      Promise<{ rows: unknown[] }>
  >();

  const transaction = jest.fn<
    (
      work: (client: { query: typeof query }) =>
        Promise<InvoiceRecord>
    ) => Promise<InvoiceRecord>
  >(async (work) => work({ query }));

  const repository = new InvoiceRepository({
    transaction,
  } as unknown as Database);

  const input = {
    id: 'invoice-001',
    sale_id: 'sale-001',
    series: 'MOCK-DEMO',
    number: '000001',
    provider_ref: 'MOCK-000001',
    issued_at: '2026-11-19T00:00:00Z',
  };

  const savedInvoice: InvoiceRecord = {
    ...input,
    status: 'ISSUED',
    issued_at: new Date(input.issued_at),
    attempts: 1,
    last_error: null,
    created_at: new Date(input.issued_at),
  };

  beforeEach(() => {
    query.mockReset();
    transaction.mockClear();
  });

  it('Lưu hóa đơn đã phát hành thành công', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{ id: 'sale-001' }],
      })
      .mockResolvedValueOnce({
        rows: [],
      })
      .mockResolvedValueOnce({
        rows: [savedInvoice],
      });

    const result = await repository.saveIssued(
      'household-001',
      input,
    );

    expect(result).toEqual(savedInvoice);
    expect(transaction).toHaveBeenCalledTimes(1);
    expect(query).toHaveBeenCalledTimes(3);

    expect(query.mock.calls[0][0]).toContain('FOR UPDATE');
    expect(query.mock.calls[0][1]).toEqual([
      'sale-001',
      'household-001',
    ]);

    expect(query.mock.calls[2][0]).toContain(
      'INSERT INTO invoices',
    );
  });

  it('Gửi lại cùng hóa đơn không tạo trùng', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{ id: 'sale-001' }],
      })
      .mockResolvedValueOnce({
        rows: [savedInvoice],
      });

    const result = await repository.saveIssued(
      'household-001',
      input,
    );

    expect(result).toEqual(savedInvoice);
    expect(query).toHaveBeenCalledTimes(2);
  });

  it('Từ chối hóa đơn khác cho cùng đơn bán', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{ id: 'sale-001' }],
      })
      .mockResolvedValueOnce({
        rows: [savedInvoice],
      });

    await expect(
      repository.saveIssued('household-001', {
        ...input,
        id: 'invoice-002',
        number: '000002',
      }),
    ).rejects.toMatchObject({
      status: 409,
    });

    expect(query).toHaveBeenCalledTimes(2);
  });

  it('Không cho lưu hóa đơn của hộ khác', async () => {
    query.mockResolvedValueOnce({
      rows: [],
    });

    await expect(
      repository.saveIssued('household-other', input),
    ).rejects.toMatchObject({
      status: 404,
    });

    expect(query).toHaveBeenCalledTimes(1);
  });

  it('Từ chối dữ liệu hóa đơn không hợp lệ', async () => {
    await expect(
      repository.saveIssued('household-001', {
        ...input,
        number: '',
      }),
    ).rejects.toMatchObject({
      status: 400,
    });

    expect(transaction).not.toHaveBeenCalled();
  });
});
});
