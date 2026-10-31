# mobile/ledger – sổ, báo cáo, nhắc hạn, onboarding

**Chủ:** Mai Trinh

## Phạm vi
- Màn sổ, báo cáo (lãi ngày, mặt hàng bán chạy, dòng tiền), nhắc hạn
- Onboarding cho người lớn tuổi, giao diện chữ lớn ít bước
- Phạm vi thuế/tờ khai được quản lý riêng tại `mobile/lib/features/tax/`
- Tính năng trợ lý AI được quản lý tại `mobile/lib/features/assistant/`

## API liên quan (xem `api/openapi.yaml`)
- `/ledger`, `/reports/*`, `/reminders`, `/tax/*`

## Việc làm ngay (tuần 1–2)
- [ ] Tuần 1: prototype Figma, thử với 2–3 chủ hộ
- [ ] Tuần 1–2: màn sổ, báo cáo, nhắc hạn trên mock
- [ ] Tuần 2: luồng onboarding lần đầu

Chỉ chủ thư mục được sửa trực tiếp. Người khác cần thay đổi thì mở issue hoặc PR để chủ duyệt.
