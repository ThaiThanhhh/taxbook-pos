import { SalesSyncController } from './sales-sync.controller';
import { SalesAccountingContextService } from './sales-accounting-context.service';
import { Module } from '@nestjs/common';

import { LedgerAuthGuard } from '../../common/http';
import { LedgerModule } from '../ledger/ledger.module';

import { SalesController } from './sales.controller';
import { SalesRepository } from './sales.repository';
import { SalesService } from './sales.service';
import { SalesLedgerAdapter } from './sales-ledger.adapter';
import { SalesPostingService } from './sales-posting.service';

@Module({
  imports: [LedgerModule],

 controllers: [
  SalesController,
  SalesSyncController,
],
  providers: [
    SalesAccountingContextService,
    LedgerAuthGuard,
    SalesRepository,
    SalesService,
    SalesLedgerAdapter,
    SalesPostingService,
  ],

  exports: [SalesService],
})
export class SalesModule {}
