# Quyết định kiến trúc (ADR) – Gate 1

Trạng thái: **đề xuất**, cả nhóm họp thống nhất rồi đổi thành "Đã chốt" (ghi ngày).

| ADR | Quyết định | Lý do | Hệ quả | Trạng thái |
|---|---|---|---|---|
| 001 | Contract-first: `api/openapi.yaml` là hợp đồng; mobile dùng mock Prism trước khi backend xong | Nhiều người làm song song | Đổi API phải sửa openapi trước, qua PR của BA | Đề xuất |
| 002 | Mobile Flutter + SQLite (drift) | Offline-first, một mã nguồn | Gia Bảo/Mai Trinh dùng chung `core/db` | Đề xuất |
| 003 | Backend NestJS + PostgreSQL; module theo `backend/src/modules/*` | Khớp phân công | Cần chốt ORM (Prisma/TypeORM) | Đề xuất |
| 004 | AI là dịch vụ FastAPI riêng, gọi qua `/ai/*`, có fallback khi nhà cung cấp lỗi | Tách rủi ro | Mã lỗi PROVIDER_UNAVAILABLE | Đề xuất |
| 005 | Tiền = số nguyên VND; thời gian UTC; khóa UUID | Tránh sai số | Chuẩn hóa cho mọi module | Đề xuất |
| 006 | Đồng bộ idempotent theo `client_op_id`; thứ tự theo `device_id`+`local_seq` | Không mất/không trùng đơn | Cần unique index | Đề xuất |
| 007 | Tham số thuế là cấu hình có phiên bản (`config/tax`, bảng `tax_param_set`); kỳ giữ version lúc tạo | Luật đổi không sửa code | Admin API `/admin/tax-param-sets` | Đề xuất |
| 008 | Hóa đơn: adapter + `mock-invoice-provider`; nhà cung cấp thật chỉ khi giảng viên cho phép | Không có sandbox thật | Q5 giảng viên | Chờ chốt |
| 009 | Hủy đơn bằng bút toán đảo, không xóa | Giữ vết kiểm toán | Sổ cái luôn cân | Đề xuất |

Câu hỏi mở: ORM; thư viện state mobile (Riverpod/Bloc); cách chạy local không Docker; quy ước base URL (`/api/v1` có hay không).
