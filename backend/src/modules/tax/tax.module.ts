import { Controller, Get, Module, NotFoundException, Query, ServiceUnavailableException } from '@nestjs/common';
import { IsDateString, IsOptional, Matches } from 'class-validator';
import { resolve } from 'node:path';
import { loadParams, selectParams } from './tax-params';

class TaxParamsQuery {
  @IsOptional() @IsDateString({ strict: true }) @Matches(/^\d{4}-\d{2}-\d{2}$/) as_of?: string;
}

@Controller('tax')
export class TaxController {
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

@Module({ controllers: [TaxController] })
export class TaxModule {}
