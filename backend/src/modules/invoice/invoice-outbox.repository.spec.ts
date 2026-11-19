
import 'reflect-metadata';

import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { jest } from '@jest/globals';

import { Database } from '../../common/database';
import {
  InvoiceOutboxRepository,
  type InvoiceOutboxRecord,
} from './invoice-outbox.repository';

describe('InvoiceOutboxRepository - enqueue', () => {
  const query = jest.fn<
    (
      sql: string,
      values?: unknown[],
    ) => Promise<{ rows: unknown[] }>
  >();

  const transaction = jest.fn<
    (
      work: (client: { query: typeof query }) =>
        Promise<InvoiceOutboxRecord>
    ) => Promise<InvoiceOutboxRecord>
  >(async (work) => work({ query }));

  const repository = new InvoiceOutboxRepository({
    transaction,
  } as unknown as Database);

  const outbox: InvoiceOutboxRecord = {
    id: 'outbox-001',
    household_id: 'household-001',
    sale_id: 'sale-001',
    invoice_id: 'invoice-001',
    amount_vnd: '90000',
    status: 'PENDING',
    attempts: 0,
    next_retry_at: new Date(),
    lease_until: null,
    last_error: null,
    created_at: new Date(),
    updated_at: new Date(),
  };

  beforeEach(() => {
    query.mockReset();
    transaction.mockClear();
  });

  it('Tạo yêu cầu PENDING thành công', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{
          id: 'sale-001',
          total_vnd: '90000',
          status: 'SYNCED',
        }],
      })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [outbox] });

    const result = await repository.enqueue(
      'household-001',
      'sale-001',
    );

    expect(result.status).toBe('PENDING');
    expect(result.invoice_id).toBe('invoice-001');
    expect(transaction).toHaveBeenCalledTimes(1);
    expect(query).toHaveBeenCalledTimes(4);

    expect(query.mock.calls[0][0]).toContain('FOR UPDATE');
    expect(query.mock.calls[0][1]).toEqual([
      'sale-001',
      'household-001',
    ]);

    expect(query.mock.calls[3][0]).toContain(
      'INSERT INTO invoice_outbox',
    );
  });

  it('Không tạo trùng khi đơn đã có trong hàng đợi', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{
          id: 'sale-001',
          total_vnd: '90000',
          status: 'SYNCED',
        }],
      })
      .mockResolvedValueOnce({ rows: [outbox] });

    const result = await repository.enqueue(
      'household-001',
      'sale-001',
    );

    expect(result.invoice_id).toBe(outbox.invoice_id);
    expect(query).toHaveBeenCalledTimes(2);
  });

  it('Từ chối đơn thuộc hộ kinh doanh khác', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    await expect(
      repository.enqueue('household-other', 'sale-001'),
    ).rejects.toThrow(NotFoundException);

    expect(query).toHaveBeenCalledTimes(1);
  });

  it('Từ chối đơn hàng đã hủy', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{
          id: 'sale-001',
          total_vnd: '90000',
          status: 'CANCELED',
        }],
      })
      .mockResolvedValueOnce({ rows: [] });

    await expect(
      repository.enqueue('household-001', 'sale-001'),
    ).rejects.toThrow(ConflictException);

    expect(query).toHaveBeenCalledTimes(2);
  });

  it('Từ chối đơn đã có hóa đơn', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{
          id: 'sale-001',
          total_vnd: '90000',
          status: 'SYNCED',
        }],
      })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({
        rows: [{ id: 'invoice-existing' }],
      });

    await expect(
      repository.enqueue('household-001', 'sale-001'),
    ).rejects.toThrow(ConflictException);

    expect(query).toHaveBeenCalledTimes(3);
  });

  it('Từ chối số tiền không hợp lệ', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{
          id: 'sale-001',
          total_vnd: '-1000',
          status: 'SYNCED',
        }],
      })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [] });

    await expect(
      repository.enqueue('household-001', 'sale-001'),
    ).rejects.toThrow(ConflictException);

    expect(query).toHaveBeenCalledTimes(3);
  });

  it('Từ chối mã đơn hàng rỗng', async () => {
    await expect(
      repository.enqueue('household-001', ''),
    ).rejects.toThrow(BadRequestException);

    expect(transaction).not.toHaveBeenCalled();
  });
});
