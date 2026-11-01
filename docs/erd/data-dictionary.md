# Từ điển dữ liệu v0 – quy ước và ánh xạ module
Sơ đồ: `erd.v0.mmd` / `erd.v0.png` (18 thực thể). Quy ước: tiền = số nguyên VND; thời gian UTC; khóa chính UUID; `client_op_id` UNIQUE trên sale.

| Thực thể | Module backend (chủ) | Màn hình mobile |
|---|---|---|
| household, app_user, device | auth (Dũng, tạm) | onboarding |
| product, stock_movement | catalog (Dũng) | pos |
| sale, sale_item, payment | sales (Dũng) | pos, payment |
| sale (đồng bộ), device.last_seq | sync (Dũng phối hợp) | core/sync |
| invoice, invoice_outbox | invoice (Dũng) | invoice |
| ledger_entry, expense, bank_statement_line | ledger (Hoài Bảo) | ledger, reports |
| tax_param_set, tax_period, tax_return_draft | tax (Hoài Bảo) | tax |
| ai_query_log | ai (Thành) | assistant |
| audit_log | common (Dũng) | – |

Việc tuần 2: thêm kiểu cột chính thức, chỉ mục, ràng buộc, rồi Hoài Bảo/Dũng viết migration trong `backend/migrations/`.
