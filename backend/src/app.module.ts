import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { LedgerModule } from './modules/ledger/ledger.module';
import { TaxModule } from './modules/tax/tax.module';

@Module({
  imports: [LedgerModule, TaxModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
