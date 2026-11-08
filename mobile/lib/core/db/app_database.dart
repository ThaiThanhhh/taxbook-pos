import 'package:drift/drift.dart';
import 'package:dt13_pos/core/db/db_values.dart';
import 'package:dt13_pos/core/db/local_database.dart';
import 'package:dt13_pos/core/db/tables.dart';

part 'app_database.g.dart';

/// Implementation drift (SQLite) của [LocalDatabase], schema v1.
///
/// Executor truyền từ ngoài vào: test dùng `NativeDatabase.memory()`,
/// app sẽ dùng `NativeDatabase(File(...))` khi nối provider (ngoài F01).
///
/// Người gọi phải bọc `insertOrder` + `insertOrderItem` + `insertOutboxEntry`
/// trong một [transaction] và không gọi mạng bên trong. Cột enum được chặn
/// hai lớp: hàm ghi ném [InvalidDbValueException], CHECK constraint chặn cả
/// chỗ ghi thẳng qua `into(...)`.
@DriftDatabase(tables: [Products, Orders, OrderItems, Outbox, DeviceCounters])
class AppDatabase extends _$AppDatabase implements LocalDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// drift mở DB lười ở truy vấn đầu tiên; gọi sớm để lỗi mở/migration
  /// lộ ra lúc khởi động chứ không phải lúc đang bán hàng.
  @override
  Future<void> open() => customSelect('SELECT 1').get();

  Future<void> insertOrder(OrdersCompanion row) async {
    if (row.paymentMethod.present) {
      requireValidPaymentMethod(row.paymentMethod.value);
    }
    await into(orders).insert(row);
  }

  Future<void> insertOrderItem(OrderItemsCompanion row) async {
    await into(orderItems).insert(row);
  }

  /// Trả về `outbox.id` tự tăng.
  Future<int> insertOutboxEntry(OutboxCompanion row) async {
    if (!row.state.present) {
      throw const InvalidDbValueException(
        column: OutboxState.column,
        value: null,
      );
    }
    requireValidOutboxState(row.state.value);
    return into(outbox).insert(row);
  }
}
