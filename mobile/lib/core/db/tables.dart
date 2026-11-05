import 'package:drift/drift.dart';
import 'package:dt13_pos/core/db/db_values.dart';

// Schema v1 (F01). Quy ước:
// - Tiền: INTEGER VND (int), không bao giờ REAL/double.
// - Thời gian: TEXT ISO-8601 UTC (vd. 2026-11-04T04:30:00.000Z).
// - Không thêm cột ngoài spec F01.
// - CHECK của cột enum lấy tập giá trị từ db_values.dart. Cách viết
//   `col.isIn(...)` trong getter của chính cột đó là cú pháp chuẩn của drift
//   nên phải tắt lint recursive_getters (drift_dev đọc AST, không gọi getter).

/// Danh mục hàng hóa lưu local.
@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get unitPriceVnd => integer().named('unit_price_vnd')();
  TextColumn get unitLabel => text().named('unit_label')();
  IntColumn get isActive =>
      integer().named('is_active').withDefault(const Constant(1))();
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Đơn bán hàng. `idempotency_key` sinh một lần lúc tạo, không bao giờ đổi.
@DataClassName('OrderRow')
@TableIndex(name: 'idx_orders_created_at', columns: {#createdAt})
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().named('idempotency_key').unique()();
  TextColumn get tempNumber => text().named('temp_number').unique()();
  // NULL vẫn qua CHECK (SQL coi kết quả NULL là đạt) -> đúng spec cho phép null.
  TextColumn get paymentMethod => text()
      .named('payment_method')
      .nullable()
      // ignore: recursive_getters
      .check(paymentMethod.isIn(PaymentMethod.dbValues))();
  IntColumn get discountVnd =>
      integer().named('discount_vnd').withDefault(const Constant(0))();
  IntColumn get totalVnd => integer().named('total_vnd')();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get devicePrefix => text().named('device_prefix')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Dòng hàng của đơn; tên và giá được chụp lại tại thời điểm bán.
@DataClassName('OrderItemRow')
@TableIndex(name: 'idx_order_items_order_id', columns: {#orderId})
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().named('order_id').references(Orders, #id)();
  TextColumn get productId => text().named('product_id')();
  TextColumn get nameSnapshot => text().named('name_snapshot')();
  IntColumn get unitPriceVnd => integer().named('unit_price_vnd')();
  IntColumn get quantity => integer()();
  IntColumn get lineDiscountVnd =>
      integer().named('line_discount_vnd').withDefault(const Constant(0))();
  IntColumn get lineTotalVnd => integer().named('line_total_vnd')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Hàng đợi gửi lên server; ghi cùng transaction với đơn.
@DataClassName('OutboxRow')
@TableIndex(name: 'idx_outbox_state_created_at', columns: {#state, #createdAt})
class Outbox extends Table {
  @override
  String get tableName => 'outbox';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get idempotencyKey => text().named('idempotency_key').unique()();
  TextColumn get payloadJson => text().named('payload_json')();
  // ignore: recursive_getters
  TextColumn get state => text().check(state.isIn(OutboxState.dbValues))();
  IntColumn get attemptCount =>
      integer().named('attempt_count').withDefault(const Constant(0))();
  TextColumn get nextAttemptAt => text().named('next_attempt_at').nullable()();
  TextColumn get lastErrorCode => text().named('last_error_code').nullable()();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at')();
}

/// Bộ đếm số tạm theo thiết bị/ngày.
@DataClassName('DeviceCounterRow')
class DeviceCounters extends Table {
  TextColumn get devicePrefix => text().named('device_prefix')();
  TextColumn get dayKey => text().named('day_key')();
  IntColumn get seq => integer()();

  @override
  Set<Column<Object>> get primaryKey => {devicePrefix};
}
