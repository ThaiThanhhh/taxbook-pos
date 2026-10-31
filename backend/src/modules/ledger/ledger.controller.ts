import { Body, Controller, Get, Headers, HttpCode, Param, Post, Query, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser, invalid, Principal } from '../../common/http';
import { BankMatchInput, BankQuery, ExpenseInput, LedgerQuery } from './dto';
import { BankService } from './bank.service';
import { LedgerService } from './ledger.service';

@Controller()
export class LedgerController {
  constructor(private readonly ledger: LedgerService, private readonly bank: BankService) {}

  @Get('ledger') list(@CurrentUser() user: Principal, @Query() query: LedgerQuery) {
    return this.ledger.list(user.household_id, query);
  }
  @Post('expenses') create(@CurrentUser() user: Principal, @Headers('idempotency-key') key: string, @Body() input: ExpenseInput) {
    return this.ledger.createExpense(user.household_id, key ?? '', input);
  }
  @Post('expenses/:expense_id/confirm') @HttpCode(200)
  confirm(@CurrentUser() user: Principal, @Param('expense_id') id: string, @Headers('idempotency-key') key: string) {
    return this.ledger.confirmExpense(user.household_id, id, key ?? '');
  }
  @Post('bank-statements/import')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 1024 * 1024, files: 1 } }))
  import(@CurrentUser() user: Principal, @UploadedFile() file?: { buffer: Buffer }) {
    if (!file?.buffer) invalid('file', 'CSV file required');
    return this.bank.import(user.household_id, file.buffer.toString('utf8'));
  }
  @Get('bank-statements/matches') bankLines(@CurrentUser() user: Principal, @Query() query: BankQuery) {
    return this.bank.list(user.household_id, query);
  }
  @Post('bank-statements/:line_id/match') @HttpCode(200)
  match(@CurrentUser() user: Principal, @Param('line_id') id: string, @Headers('idempotency-key') key: string, @Body() input: BankMatchInput) {
    return this.bank.match(user.household_id, id, key ?? '', input);
  }
}
