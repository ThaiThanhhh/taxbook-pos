# Kiến trúc tổng quan v0
Mobile (Flutter, SQLite) → API (`api/openapi.yaml`) → Backend (NestJS + PostgreSQL) → AI (FastAPI) và nhà cung cấp hóa đơn (mock/sandbox).

| Tầng | Thư mục | Chủ |
|---|---|---|
| Mobile core (db, network, sync) | mobile/lib/core | Gia Bảo |
| Mobile POS, thanh toán, hóa đơn | mobile/lib/features/{pos,payment,invoice} | Gia Bảo |
| Mobile sổ cái, báo cáo, thuế, onboarding, trợ lý, widgets | mobile/lib/features/{ledger,reports,tax,onboarding,assistant}, core/widgets | Mai Trinh |
| Backend sales, catalog, invoice, sync | backend/src/modules/* | Quang Dũng |
| Backend ledger, tax | backend/src/modules/{ledger,tax} | Hoài Bảo |
| AI | ai/app/{routers,schemas,services} | Văn Thành |
| Kiểm thử, hạ tầng, công cụ | tests, infra, tools, .github | Tấn Tài |

Luồng offline-first: tạo đơn trong SQLite (mã TMP-device-seq) → hàng đợi đồng bộ → `/sync/sales` idempotent theo client_op_id → server cấp số hóa đơn chính thức → ghi sổ cái theo client_created_at.

Sơ đồ AS-IS (giả định, chưa khảo sát): `arch.png`. Việc tuần 2: BPMN TO-BE, sơ đồ tuần tự sync, quyết định công nghệ (ADR).
