
import {
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';

import type { SyncSaleDto } from './dto/sync-sales.dto';
import type { SaleLedgerContext } from './sales-ledger.adapter';

@Injectable()
export class SalesAccountingContextService {
  async resolve(
    _householdId: string,
    _sale: SyncSaleDto,
  ): Promise<
    Pick<SaleLedgerContext, 'entryDate' | 'sectorCode'>
  > {
    // Chưa có nguồn mã ngành đáng tin cậy từ Catalog.
    // Không tự gán mã ngành mặc định hoặc lấy từ mobile.
    // Tạm thời từ chối đồng bộ để tránh ghi sai Ledger.
    throw new ServiceUnavailableException(
      'Chưa cấu hình nguồn dữ liệu kế toán cho Sales',
    );
  }
}
