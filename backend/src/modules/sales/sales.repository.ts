
import {
  ConflictException,
  Injectable,
} from '@nestjs/common';

import {
  Database,
  type SqlClient,
} from '../../common/database';
import type { SyncSaleDto } from './dto/sync-sales.dto';

interface SaleAmounts {
  totalVnd: number;
  discountVnd: number;
}

@Injectable()
export class SalesRepository {
  constructor(private readonly database: Database) {}


  // Tìm đơn bán thuộc đúng hộ kinh doanh
  async findById(householdId: string, saleId: string) {
    const result = await this.database.query(
      `SELECT
         id,
         client_op_id,
         device_id,
         local_seq,
         total_vnd,
         discount_vnd,
         status,
         client_created_at,
         created_at
       FROM sales
       WHERE id = $1
         AND household_id = $2
       LIMIT 1`,
      [saleId, householdId],
    );

    return result.rows[0] ?? null;
  }


  // Lưu một giao dịch bán trong transaction

async createSale(
  householdId: string,
  deviceId: string,
  sale: SyncSaleDto,
  amounts: SaleAmounts,
  onAccepted?: (
    client: SqlClient,
    saleId: string,
  ) => Promise<void>,
) {

    return this.database.transaction(async (client) => {
      // 1. Lưu thông tin đơn bán

      const inserted = await client.query<{ id: string }>(
        `INSERT INTO sales (
           household_id,
           client_op_id,
           device_id,
           local_seq,
           tmp_number,
           total_vnd,
           discount_vnd,
           status,
           client_created_at
         )
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'SYNCED', $8)
         ON CONFLICT DO NOTHING
         RETURNING id`,
        [
          householdId,
          sale.client_op_id,
          deviceId,
          sale.local_seq,
          sale.tmp_number ?? null,
          amounts.totalVnd.toString(),
          amounts.discountVnd.toString(),
          sale.client_created_at,
        ],
      );


      // 2. Xử lý trường hợp đơn đã tồn tại
      if (inserted.rows.length === 0) {
        const existing = await client.query<{
          id: string;
          device_id: string;
          local_seq: number;
          status: string;
        }>(
          `SELECT id, device_id, local_seq, status
           FROM sales
           WHERE client_op_id = $1
             AND household_id = $2`,
          [sale.client_op_id, householdId],
        );

        const previousSale = existing.rows[0];

        if (previousSale) {
          if (
            previousSale.device_id !== deviceId ||
            previousSale.local_seq !== sale.local_seq
          ) {
            throw new ConflictException(
              'client_op_id không khớp thiết bị hoặc thứ tự đơn',
            );
          }

          return {
            sale_id: previousSale.id,
            status: previousSale.status,
            duplicate: true,
          };
        }

        throw new ConflictException(
          'Thiết bị đã sử dụng local_seq này cho đơn khác',
        );
      }

      const saleId = inserted.rows[0].id;

      // 3. Lưu các sản phẩm trong đơn
      for (let index = 0; index < sale.items.length; index++) {
        const item = sale.items[index];

        await client.query(
          `INSERT INTO sale_items (
             sale_id,
             line_no,
             product_id,
             qty,
             unit_price_vnd
           )
           VALUES ($1, $2, $3, $4, $5)`,
          [
            saleId,
            index + 1,
            item.product_id,
            item.qty,
            item.unit_price_vnd.toString(),
          ],
        );
      }

      // 4. Lưu các khoản thanh toán
      for (const payment of sale.payments) {
        await client.query(
          `INSERT INTO payments (
             sale_id,
             method,
             amount_vnd,
             reference
           )
           VALUES ($1, $2, $3, $4)`,
          [
            saleId,
            payment.method,
            payment.amount_vnd.toString(),
            payment.reference ?? null,
          ],
        );
      }


// 5. Gọi xử lý bổ sung trong cùng transaction
// Sau này sẽ dùng để ghi nhận doanh thu Ledger.
if (onAccepted) {
  await onAccepted(client, saleId);
}

// 6. Hoàn tất giao dịch
return {
  sale_id: saleId,
  status: 'SYNCED',
  duplicate: false,
};

    });
  }
}
