
import { Module } from '@nestjs/common';

import { AppController } from './app.controller';
import { AppService } from './app.service';

import { LedgerModule } from './modules/ledger/ledger.module';
import { TaxModule } from './modules/tax/tax.module';
import { SalesModule } from './modules/sales/sales.module';

import { InvoiceModule } from './modules/invoice/invoice.module';
@Module({
  imports: [
    LedgerModule,
    TaxModule,
    SalesModule,
    InvoiceModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
