# backend/sales – bán hàng, đồng bộ, hóa đơn

**Chủ:** Quang Dũng

## Phạm vi
- Sản phẩm, đơn bán, thanh toán, tồn kho
- Nhận lô đơn từ thiết bị, chống tạo trùng bằng `client_op_id`, xử lý theo `(device_id, local_seq)`
- Phát hành hóa đơn qua mock nhà cung cấp, hàng đợi gửi lại

## API liên quan (xem `api/openapi.yaml`)
- `/products*`, `/sync/*`, `/sales/*`, `/invoices*`

## Việc làm ngay (tuần 1–2)
- [ ] Tuần 1: migration `product`, `sale`, `sale_item`, `payment`, `device`; API sản phẩm và tra mã vạch
- [ ] Tuần 1–2: `POST /sync/sales` + test trùng lặp
- [ ] Tuần 2: mock nhà cung cấp hóa đơn (cấu hình được trả 503), `invoice`, `invoice_outbox`

Chỉ chủ thư mục được sửa trực tiếp. Người khác cần thay đổi thì mở issue hoặc PR để chủ duyệt.
