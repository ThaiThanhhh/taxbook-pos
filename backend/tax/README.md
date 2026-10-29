# backend/tax – engine thuế, kỳ thuế, tờ khai

**Chủ:** Hoài Bảo

## Phạm vi
- Nạp tham số thuế có phiên bản và ngày hiệu lực
- Tính GTGT và TNCN theo kỳ
- Chốt kỳ, tờ khai mẫu, nhắc hạn, báo cáo

## API liên quan (xem `api/openapi.yaml`)
- `/tax/*`, `/reports/*`, `/reminders`, `/admin/tax-param-sets`

## Việc làm ngay (tuần 1–2)
- [ ] Tuần 1: migration `tax_param_set`, `tax_period`; bộ nạp từ `config/tax/`
- [ ] Tuần 1–2: engine thuế thuần (không phụ thuộc DB) + test 2 phép tính mẫu
- [ ] Tuần 2: `GET /tax/params`

Chỉ chủ thư mục được sửa trực tiếp. Người khác cần thay đổi thì mở issue hoặc PR để chủ duyệt.
