import { Module } from '@nestjs/common';
import { LedgerController } from './ledger.controller';
import { LedgerService } from './ledger.service';
import { BankService } from './bank.service';
import { LedgerAuthGuard } from '../../common/http';

@Module({ controllers: [LedgerController], providers: [LedgerService, BankService, LedgerAuthGuard], exports: [LedgerService] })
export class LedgerModule {}
