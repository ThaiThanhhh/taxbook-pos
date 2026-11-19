
import 'reflect-metadata';

import { Test } from '@nestjs/testing';
import { Database, DatabaseModule } from '../../common/database';

import { InvoiceModule } from './invoice.module';
import { InvoiceRepository } from './invoice.repository';
import { InvoiceOutboxRepository } from './invoice-outbox.repository';
import { MockInvoiceProvider } from './mock-invoice.provider';
import { InvoiceOutboxWorkerService } from './invoice-outbox-worker.service';

describe('InvoiceModule - Dependency Injection', () => {
  it('Khởi tạo đầy đủ các thành phần Invoice', async () => {
    const fakeDatabase = {
      query: async () => ({ rows: [] }),
      onModuleDestroy: async () => {},
    } as unknown as Database;

    const moduleRef = await Test.createTestingModule({
      imports: [
        DatabaseModule.register(fakeDatabase),
        InvoiceModule,
      ],
    }).compile();

    try {
      expect(
        moduleRef.get(InvoiceRepository),
      ).toBeInstanceOf(InvoiceRepository);

      expect(
        moduleRef.get(InvoiceOutboxRepository),
      ).toBeInstanceOf(InvoiceOutboxRepository);

      expect(
        moduleRef.get(MockInvoiceProvider),
      ).toBeInstanceOf(MockInvoiceProvider);

      expect(
        moduleRef.get(InvoiceOutboxWorkerService),
      ).toBeInstanceOf(InvoiceOutboxWorkerService);

      expect(moduleRef.get(Database)).toBe(fakeDatabase);
    } finally {
      await moduleRef.close();
    }
  });
});
