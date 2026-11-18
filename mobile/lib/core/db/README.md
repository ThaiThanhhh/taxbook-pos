Mobile database — Gia Bảo

SQLite offline-first qua drift, schemaVersion 2 (F01, F08).

## Package

- `drift ^2.35.3` — ORM + migration.
- `sqlite3_flutter_libs ^0.6.0+eol` — bản rỗng, chỉ để chặn ai đó kéo nhầm
  0.5.x (build script cũ, xung đột với sqlite3 3.x). SQLite native do
  `sqlite3 3.x` tự đóng gói qua build hooks.
- `drift_dev ^2.35.2` (dev) — chạy được với `build_runner ^2.16.2`,
  không đòi 2.17.

## File

- `local_database.dart` — interface `LocalDatabase` (open/close) + provider.
  Từ F06 provider trả cùng `AppDatabase` với `appDatabaseProvider`
  (file SQLite thật, xem `app_database_provider.dart`).
- `db_values.dart` — Dart thuần: `OutboxState`, `PaymentMethod`,
  `InvalidDbValueException`. Tập giá trị hợp lệ nằm ở đây, dùng chung cho
  tầng ghi lẫn CHECK constraint.
- `tables.dart` — schema: products, orders, order_items, outbox,
  device_counters. Tiền là INTEGER, thời gian là TEXT ISO-8601 UTC.
  `order_items.order_id` có khóa ngoại tới `orders.id` (không phải cột
  thêm): dòng hàng không được tồn tại khi đơn không còn.
- `app_database.dart` — `AppDatabase extends _$AppDatabase implements
  LocalDatabase`. Executor truyền từ ngoài: test dùng
  `NativeDatabase.memory()`, app dùng file `dt13_pos.sqlite` trong thư mục
  dữ liệu riêng của app (`app_database_provider.dart`).
- `drift_order_write_dao.dart` — cài đặt `OrderWriteDao`
  (`lib/core/ports/order_write_dao.dart`) cho `SaveOrder` (F08).
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

## F08 – schema orders đóng băng cho Dev 2

- schemaVersion 2: `device_counters` có khóa chính (device_prefix, day_key),
  mỗi ngày một hàng; hàng ngày cũ không bị sửa. Migration v1 -> v2 dựng lại
  bảng bằng `TableMigration` và giữ nguyên hàng cũ.
- `orders.discount_vnd` = tổng giảm cả đơn, gồm giảm từng dòng.
  `total_vnd` = Σ(unit_price_vnd × quantity) − discount_vnd.
- `created_at` là ISO-8601 UTC. `day_key` (yyMMdd) tính theo giờ Việt Nam.
- `temp_number` = `A1-<yyMMdd>-<seq 4 số>`; `device_prefix` cố định 'A1'
  (`lib/core/constants/device_prefix.dart`).
- Đơn đã ghi không UPDATE. Ghi qua `SaveOrder` (features/sales/domain),
  DAO hợp đồng ở `lib/core/ports/order_write_dao.dart`.
