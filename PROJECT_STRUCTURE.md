# Cấu trúc dự án DT13 — Bán là có sổ

Đây là bản mở rộng cấu trúc từ scaffold ban đầu. Các file có sẵn trong ZIP được giữ lại; các thư mục mới được bổ sung README.md để Git/ZIP lưu được thư mục và ghi rõ mục đích/người phụ trách. Đây là scaffold, chưa phải ứng dụng hoàn chỉnh.

## Phân công chính
- **Ngọc Thái (BA/Lead):** `docs/`, `api/openapi.yaml`, `config/tax/`
- **Gia Bảo:** `mobile/lib/core/`, `mobile/lib/features/pos/`, `payment/`, `invoice/`
- **Mai Trinh:** `mobile/lib/features/ledger/`, `reports/`, `tax/`, `onboarding/`, `assistant/`, `core/widgets/`
- **Quang Dũng:** `backend/src/modules/sales/`, `catalog/`, `invoice/`, phối hợp `sync/`
- **Hoài Bảo:** `backend/src/modules/ledger/`, `tax/`
- **Văn Thành:** `ai/`
- **Tấn Tài:** `tools/`, `tests/`, `infra/`, `.github/`

## Quy ước cần giữ
1. `api/openapi.yaml` là hợp đồng API dùng chung; thay đổi cần báo cho bên mobile/backend và cập nhật kiểm thử.
2. Cấu hình thuế trong `config/tax/` phải được kiểm tra với văn bản pháp lý gốc và giảng viên. Mọi giá trị chưa xác minh phải gắn trạng thái `DRAFT_UNVERIFIED`, không dùng để khẳng định nghĩa vụ thuế thực tế.
3. Dùng dữ liệu giả lập/đã ẩn danh trong repo; không commit `.env` thật, mật khẩu thật hoặc hóa đơn chưa ẩn thông tin.
4. Thống nhất một framework/backend stack và quy tắc base URL trước khi tích hợp.
5. Thư mục mới là điểm đặt mã nguồn dự kiến; README hiện có trong scaffold ban đầu vẫn là nguồn hướng dẫn cho các module tương ứng.
