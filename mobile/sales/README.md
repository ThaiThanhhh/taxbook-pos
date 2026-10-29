# mobile/sales – bán hàng và offline

**Chủ:** Gia Bảo

## Phạm vi
- Màn bán hàng, quét mã vạch, thanh toán tiền mặt và QR
- Lưu SQLite trước, `client_op_id`, `local_seq`, biên lai tạm `TMP-…`
- Đồng bộ nền theo lô, thử lại, hiển thị số đơn chờ

## API liên quan (xem `api/openapi.yaml`)
- `/products*`, `/sync/*`, `/sales/*`

## Việc làm ngay (tuần 1–2)
- [ ] Tuần 1: lược đồ SQLite, màn bán hàng chạy trên mock
- [ ] Tuần 1–2: bán được khi tắt mạng
- [ ] Tuần 2: bộ đồng bộ nền gửi `POST /sync/sales` tới mock

Chỉ chủ thư mục được sửa trực tiếp. Người khác cần thay đổi thì mở issue hoặc PR để chủ duyệt.
