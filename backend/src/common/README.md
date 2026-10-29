# backend/common – khung dùng chung

**Chủ:** Quang Dũng (khung), Hoài Bảo dùng lại

## Phạm vi
- Xác thực JWT, phân quyền OWNER/STAFF/ACCOUNTANT/ADMIN
- Khung lỗi chuẩn `ErrorEnvelope`
- Middleware `Idempotency-Key`
- Nhật ký thao tác (`audit_log`), cô lập dữ liệu theo hộ

## API liên quan (xem `api/openapi.yaml`)
- `/auth/login`, `/auth/refresh`
- Khung lỗi dùng cho mọi endpoint

## Việc làm ngay (tuần 1–2)
- [ ] Ngày 2: đẩy khung xác thực, lỗi chuẩn, idempotency để Hoài Bảo dùng lại
- [ ] Tuần 1: bảng `household`, `user`, `audit_log`

Chỉ chủ thư mục được sửa trực tiếp. Người khác cần thay đổi thì mở issue hoặc PR để chủ duyệt.
