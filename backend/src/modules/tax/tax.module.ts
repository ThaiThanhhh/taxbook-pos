import { Controller, Get, Module, NotFoundException, Query, ServiceUnavailableException, UseGuards } from '@nestjs/common';
import { Database } from '../../common/database';
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
  constructor(private readonly database: Database) {}

  @Get('periods')
  async periods(@CurrentUser() user: Principal) {
    const result = await this.database.query(`SELECT id,label,start_date::text,end_date::text,status,
      revenue_vnd::float8,vat_vnd::float8,pit_vnd::float8,method,param_set_id
      FROM tax_period WHERE household_id=$1 ORDER BY start_date,id`, [user.household_id]);
    return { items: result.rows.map(row => Object.fromEntries(Object.entries(row).filter(([,value]) => value !== null))) };
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

@Module({ controllers: [TaxController], providers: [LedgerAuthGuard] })
export class TaxModule {}
