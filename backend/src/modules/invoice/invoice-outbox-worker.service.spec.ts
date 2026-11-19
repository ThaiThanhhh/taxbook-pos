
import 'reflect-metadata';

import { afterAll, beforeEach, describe, expect, it, jest } from '@jest/globals';

import {
  InvoiceOutboxRepository,
  type InvoiceOutboxRecord,
} from './invoice-outbox.repository';
import { MockInvoiceProvider } from './mock-invoice.provider';
import { InvoiceOutboxWorkerService } from './invoice-outbox-worker.service';

describe('InvoiceOutboxWorkerService', () => {
  const originalMode = process.env.INVOICE_MOCK_MODE;

  const job: InvoiceOutboxRecord = {
    id: 'outbox-001',
    household_id: 'household-001',
    sale_id: 'sale-001',
    invoice_id: 'invoice-001',
    amount_vnd: '90000',
    status: 'PROCESSING',
    attempts: 1,
    next_retry_at: null,
    lease_until: new Date(),
    last_error: null,
    created_at: new Date(),
    updated_at: new Date(),
  };

  const claimNext = jest.fn<
    () => Promise<InvoiceOutboxRecord | null>
  >();

  const markFailure = jest.fn<
    (
      id: string,
      attempt: number,
      reason: string,
    ) => Promise<InvoiceOutboxRecord | null>
  >();

  const completeIssued = jest.fn<
    (
      id: string,
      attempt: number,
      issued: {
        series: string;
        number: string;
        provider_ref: string;
        issued_at: string;
      },
    ) => Promise<InvoiceOutboxRecord | null>
  >();

  const worker = new InvoiceOutboxWorkerService(
    {
      claimNext,
      markFailure,
      completeIssued,
    } as unknown as InvoiceOutboxRepository,
    new MockInvoiceProvider(),
  );

  beforeEach(() => {
    delete process.env.INVOICE_MOCK_MODE;
    claimNext.mockReset();
    markFailure.mockReset();
    completeIssued.mockReset();
  });

  afterAll(() => {
    if (originalMode === undefined) {
      delete process.env.INVOICE_MOCK_MODE;
    } else {
      process.env.INVOICE_MOCK_MODE = originalMode;
    }
  });

  it('Không có công việc thì trả EMPTY', async () => {
    claimNext.mockResolvedValue(null);

    expect(await worker.processNext()).toEqual({
      status: 'EMPTY',
    });

    expect(markFailure).not.toHaveBeenCalled();
    expect(completeIssued).not.toHaveBeenCalled();
  });

  it('Provider 503 chuyển sang RETRY', async () => {
    claimNext.mockResolvedValue(job);
    markFailure.mockResolvedValue({
      ...job,
      status: 'RETRY',
    });

    const result = await worker.processNext();

    expect(result.status).toBe('RETRY');
    expect(markFailure).toHaveBeenCalledWith(
      job.id,
      1,
      expect.any(String),
    );
    expect(completeIssued).not.toHaveBeenCalled();
  });

  it('Provider thành công chuyển sang ISSUED', async () => {
    process.env.INVOICE_MOCK_MODE = 'SUCCESS';

    claimNext.mockResolvedValue(job);
    completeIssued.mockResolvedValue({
      ...job,
      status: 'ISSUED',
    });

    const result = await worker.processNext();

    expect(result).toEqual({
      status: 'ISSUED',
      invoice_id: job.invoice_id,
    });

    expect(completeIssued).toHaveBeenCalledWith(
      job.id,
      1,
      expect.objectContaining({
        status: 'ISSUED',
        series: 'MOCK-DEMO',
      }),
    );

    expect(markFailure).not.toHaveBeenCalled();
  });

  it('Lần thất bại cuối trả FAILED', async () => {
    claimNext.mockResolvedValue({
      ...job,
      attempts: 5,
    });

    markFailure.mockResolvedValue({
      ...job,
      attempts: 5,
      status: 'FAILED',
    });

    expect((await worker.processNext()).status).toBe(
      'FAILED',
    );
  });

  it('Worker hết quyền hoàn tất trả STALE', async () => {
    process.env.INVOICE_MOCK_MODE = 'SUCCESS';

    claimNext.mockResolvedValue(job);
    completeIssued.mockResolvedValue(null);

    const result = await worker.processNext();

    expect(result.status).toBe('STALE');
  });
});
