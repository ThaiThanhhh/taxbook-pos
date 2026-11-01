import { Controller, Get, Module, NotFoundException, Query, ServiceUnavailableException, UseGuards } from '@nestjs/common';
import { TaxPeriodService } from './tax-period.service';
import { LedgerModule } from '../ledger/ledger.module';
import { CurrentUser, LedgerAuthGuard } from '../../common/http';
import type { Principal } from '../../common/http';
import { IsDateString, IsOptional, Matches } from 'class-validator';
import { resolve } from 'node:path';
import { loadParams, selectParams } from './tax-params';

class TaxParamsQuery {
  @IsOptional() @IsDateString({ strict: true }) @Matches(/^\d{4}-\d{2}-\d{2}$/) as_of?: string;
}

@Controller('tax')
@UseGuards(LedgerAuthGuard)
export class TaxController {
  constructor(private readonly periodsService: TaxPeriodService) {}

  @Get('periods')
  async periods(@CurrentUser() user: Principal) {
    return this.periodsService.list(user.household_id);
  }
  @Get('params')
  async params(@Query() query: TaxParamsQuery) {
    let params;
    try { params = await loadParams(resolve(process.env.TAX_CONFIG_DIR ?? '../config/tax')); }
    catch (error) { console.error(error); throw new ServiceUnavailableException('Tax configuration unavailable'); }
    const selected = selectParams(params, query.as_of ?? new Date().toISOString().slice(0, 10));
    if (!selected) throw new NotFoundException('No approved tax parameters effective on this date');
    return selected;
  }
}

@Module({ imports: [LedgerModule], controllers: [TaxController], providers: [LedgerAuthGuard, TaxPeriodService], exports: [TaxPeriodService] })
export class TaxModule {}
