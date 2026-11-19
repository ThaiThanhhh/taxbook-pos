
import { Module } from '@nestjs/common';

import { InvoiceRepository } from './invoice.repository';
import { InvoiceOutboxRepository } from './invoice-outbox.repository';
import { MockInvoiceProvider } from './mock-invoice.provider';
import { InvoiceOutboxWorkerService } from './invoice-outbox-worker.service';

@Module({
  providers: [
    InvoiceRepository,
    InvoiceOutboxRepository,
    MockInvoiceProvider,
    InvoiceOutboxWorkerService,
  ],
  exports: [
    InvoiceRepository,
    InvoiceOutboxRepository,
    InvoiceOutboxWorkerService,
  ],
})
export class InvoiceModule {}
