
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
  
  // Lấy chi tiết đơn bán thuộc đúng hộ kinh doanh
  async findById(householdId: string, saleId: string) {
    const result = await this.database.query<{
      id: string;
      client_op_id: string;
      device_id: string;
      local_seq: number;
      tmp_number: string | null;
      total_vnd: string;
      discount_vnd: string;
      status: string;
      client_created_at: Date;
      created_at: Date;
      items: Array<{
        product_id: string;
        qty: number;
        unit_price_vnd: string;
        line_total_vnd: string;
      }>;
      payments: Array<{
        method: string;
        amount_vnd: string;
        reference: string | null;
      }>;
    }>(
      `SELECT
         s.id,
         s.client_op_id,
         s.device_id,
         s.local_seq,
         s.tmp_number,
         s.total_vnd::text AS total_vnd,
         s.discount_vnd::text AS discount_vnd,
         s.status,
         s.client_created_at,
         s.created_at,

         COALESCE((
           SELECT jsonb_agg(
             jsonb_build_object(
               'product_id', si.product_id,
               'qty', si.qty,
               'unit_price_vnd', si.unit_price_vnd::text,
               'line_total_vnd', si.line_total_vnd::text
             )
             ORDER BY si.line_no
           )
           FROM sale_items si
           WHERE si.sale_id = s.id
         ), '[]'::jsonb) AS items,

         COALESCE((
           SELECT jsonb_agg(
             jsonb_build_object(
               'method', p.method,
               'amount_vnd', p.amount_vnd::text,
               'reference', p.reference
             )
             ORDER BY p.created_at, p.id
           )
           FROM payments p
           WHERE p.sale_id = s.id
         ), '[]'::jsonb) AS payments

       FROM sales s
       WHERE s.id = $1
         AND s.household_id = $2
       LIMIT 1`,
      [saleId, householdId],
    );

    const sale = result.rows[0];

    if (!sale) {
      return null;
    }

    // Chỉ chuyển BIGINT thành number khi còn trong giới hạn an toàn
    const toSafeMoney = (value: string): number => {
      const amount = Number(value);

      if (!Number.isSafeInteger(amount) || amount < 0) {
        throw new Error('Số tiền vượt giới hạn an toàn');
      }

      return amount;
    };

    return {
      ...sale,
      total_vnd: toSafeMoney(sale.total_vnd),
      discount_vnd: toSafeMoney(sale.discount_vnd),
      items: sale.items.map((item) => ({
        ...item,
        unit_price_vnd: toSafeMoney(item.unit_price_vnd),
        line_total_vnd: toSafeMoney(item.line_total_vnd),
      })),
      payments: sale.payments.map((payment) => ({
        ...payment,
        amount_vnd: toSafeMoney(payment.amount_vnd),
      })),
    };
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
