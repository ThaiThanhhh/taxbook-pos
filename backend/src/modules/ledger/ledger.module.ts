import { Module } from '@nestjs/common';
import { LedgerController } from './ledger.controller';
import { LedgerService } from './ledger.service';
import { BankService } from './bank.service';

@Module({ controllers: [LedgerController], providers: [LedgerService, BankService], exports: [LedgerService] })
export class LedgerModule {}
