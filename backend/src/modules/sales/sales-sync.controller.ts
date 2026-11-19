
import {
  Body,
  Controller,
  HttpCode,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';

import {
  CurrentUser,
  LedgerAuthGuard,
  type Principal,
} from '../../common/http';

import { SyncSalesRequestDto } from './dto/sync-sales.dto';
import { SalesPostingService } from './sales-posting.service';
import { SalesAccountingContextService } from './sales-accounting-context.service';

@Controller('sync/sales')
@UseGuards(LedgerAuthGuard)
export class SalesSyncController {
  constructor(
    private readonly postingService: SalesPostingService,
    private readonly accountingContext: SalesAccountingContextService,
  ) {}

  @Post()
  @HttpCode(200)
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  )
  async syncSales(
    @CurrentUser() user: Principal,
    @Body() body: SyncSalesRequestDto,
  ) {
    return this.postingService.syncAcceptedSalesBatch(
      user.household_id,
      body.device_id,
      body.sales,
      (sale) =>
        this.accountingContext.resolve(
          user.household_id,
          sale,
        ),
    );
  }
}
