import { Module } from '@nestjs/common';
import { LedgerController } from './ledger.controller';
import { LedgerService } from './ledger.service';
import { BankService } from './bank.service';
import { LedgerAuthGuard } from '../../common/http';
import { LedgerSummaryService } from './ledger-summary.service';

@Module({ controllers: [LedgerController], providers: [LedgerService, BankService, LedgerAuthGuard, LedgerSummaryService], exports: [LedgerService, LedgerSummaryService] })
export class LedgerModule {}
