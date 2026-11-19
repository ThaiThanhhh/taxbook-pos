
import {
  Controller,
  Get,
  Param,
  UseGuards,
} from '@nestjs/common';

import {
  CurrentUser,
  LedgerAuthGuard,
  type Principal,
} from '../../common/http';

import { SalesService } from './sales.service';

@Controller('sales')
@UseGuards(LedgerAuthGuard)
export class SalesController {
  constructor(
    private readonly salesService: SalesService,
  ) {}

  @Get(':sale_id')
  async findById(
    @CurrentUser() user: Principal,
    @Param('sale_id') saleId: string,
  ) {
    return this.salesService.findById(
      user.household_id,
      saleId,
    );
  }
}
