# backend/ledger – sổ, chi phí, sao kê

**Chủ:** Hoài Bảo

## Phạm vi
- Ghi sổ tự động từ đơn bán theo ngày bán
- Chi phí (tay và từ OCR sau khi xác nhận)
- Nhập và gợi ý khớp sao kê

## API liên quan (xem `api/openapi.yaml`)
- `/ledger`, `/expenses*`, `/bank-statements*`

## Việc làm ngay (tuần 1–2)
- [ ] Tuần 1: migration `ledger_entry`, `expense`, `bank_statement_line`
- [ ] Tuần 2: `GET /ledger`, `POST /expenses`; parser sao kê CSV giả lập

Chỉ chủ thư mục được sửa trực tiếp. Người khác cần thay đổi thì mở issue hoặc PR để chủ duyệt.
