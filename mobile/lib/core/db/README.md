Mobile database — Gia Bảo

SQLite offline-first qua drift, schemaVersion 1 (F01).

## Package

- `drift ^2.35.3` — ORM + migration.
- `sqlite3_flutter_libs ^0.6.0+eol` — bản rỗng, chỉ để chặn ai đó kéo nhầm
  0.5.x (build script cũ, xung đột với sqlite3 3.x). SQLite native do
  `sqlite3 3.x` tự đóng gói qua build hooks.
- `drift_dev ^2.35.2` (dev) — chạy được với `build_runner ^2.16.2`,
  không đòi 2.17.

## File

- `local_database.dart` — interface `LocalDatabase` (open/close) + provider.
  Chữ ký giữ nguyên; provider vẫn trả `NoopLocalDatabase` cho đến khi có
  đường dẫn file DB trên máy (bước sau, không thuộc F01).
- `db_values.dart` — Dart thuần: `OutboxState`, `PaymentMethod`,
  `InvalidDbValueException`. Tập giá trị hợp lệ nằm ở đây, dùng chung cho
  tầng ghi lẫn CHECK constraint.
- `tables.dart` — schema: products, orders, order_items, outbox,
  device_counters. Tiền là INTEGER, thời gian là TEXT ISO-8601 UTC.
  `order_items.order_id` có khóa ngoại tới `orders.id` (không phải cột
  thêm): dòng hàng không được tồn tại khi đơn không còn.
- `app_database.dart` — `AppDatabase extends _$AppDatabase implements
  LocalDatabase`. Executor truyền từ ngoài: test dùng
  `NativeDatabase.memory()`, app sau này dùng `NativeDatabase(File(...))`.
- `app_database.g.dart` — code drift sinh ra, **được commit** (xem
  `.gitignore`). Khi sửa schema phải chạy lại `dart run build_runner build`
  và commit file này.

## Quy tắc ghi

- Ghi đơn + outbox luôn trong một `transaction`; không gọi mạng bên trong.
- `insertOutboxEntry` chỉ nhận state `pending | sending | done |
  failed_retryable | failed_permanent`; `insertOrder` chỉ nhận
  payment_method `cash | bank_qr | null`. Sai thì ném
  `InvalidDbValueException` (không dùng assert — assert tắt ở release).
- CHECK constraint trong schema là lớp chặn thứ hai cho cả những chỗ ghi
  thẳng qua `into(...)`.
- `idempotency_key` UNIQUE: sinh một lần lúc tạo đơn, không bao giờ đổi.
