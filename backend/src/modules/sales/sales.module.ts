
import { Module } from '@nestjs/common';

import { LedgerModule } from '../ledger/ledger.module';

import { SalesRepository } from './sales.repository';
import { SalesService } from './sales.service';
import { SalesLedgerAdapter } from './sales-ledger.adapter';
import { SalesPostingService } from './sales-posting.service';

@Module({
  imports: [
    LedgerModule,
  ],

  providers: [
  SalesRepository,
  SalesService,
  SalesLedgerAdapter,
  SalesPostingService,
],

  exports: [
    SalesService,
  ],
})
export class SalesModule {}
