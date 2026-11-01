import type { SqlClient } from '../../common/database';

/** Accepted sale projection, not a proposed Sales/Household database schema.
 * household is obtained from trusted Sales ownership, never from mobile input.
 * entry_date is the original business date; amounts are integer VND.
 */
export interface SalePosting {
  sale_id: string; entry_date: string; amount_vnd: number; sector_code: string;
  payments: { method: 'CASH' | 'QR_TRANSFER' | 'CARD'; amount_vnd: number }[];
}
export interface SalesLedgerPort {
  /** Pass the active Sales transaction to commit/rollback together.
   * Without it, Sales must persist an outbox and retry; not an atomic dual write.
   * Caller must propagate errors and roll back; do not swallow errors then commit.
   */
  recordSale(household: string, input: SalePosting, transaction?: SqlClient): Promise<{ duplicate: boolean }>;
  /** Preserve originals and create reversing entries. Retry is safe. */
  reverseSale(household: string, saleId: string, reason: string, transaction?: SqlClient): Promise<{ duplicate: boolean }>;
}
