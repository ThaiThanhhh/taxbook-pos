import 'package:drift/drift.dart';
import 'package:dt13_pos/core/db/app_database.dart';
import 'package:dt13_pos/core/db/db_values.dart';
import 'package:dt13_pos/core/ports/order_write_dao.dart';

/// [OrderWriteDao] trên SQLite (drift).
///
/// Bên trong `transaction` của drift, mọi lệnh gọi qua [_db] đi vào chính
/// transaction đó, nên các hàm ghi ở đây tự rơi vào transaction của SaveOrder.
final class DriftOrderWriteDao implements OrderWriteDao {
  const DriftOrderWriteDao(this._db);

  final AppDatabase _db;

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  @override
  Future<int> nextDaySeq({
    required String devicePrefix,
    required String dayKey,
  }) async {
    Expression<bool> sameDay($DeviceCountersTable c) =>
        c.devicePrefix.equals(devicePrefix) & c.dayKey.equals(dayKey);

    final current = await (_db.select(
      _db.deviceCounters,
    )..where(sameDay)).getSingleOrNull();
    if (current == null) {
      await _db
          .into(_db.deviceCounters)
          .insert(
            DeviceCountersCompanion.insert(
              devicePrefix: devicePrefix,
              dayKey: dayKey,
              seq: 1,
            ),
          );
      return 1;
    }
    final next = current.seq + 1;
    await (_db.update(
      _db.deviceCounters,
    )..where(sameDay)).write(DeviceCountersCompanion(seq: Value(next)));
    return next;
  }

  @override
  Future<void> insertOrder(NewOrder order) => _db.insertOrder(
    OrdersCompanion.insert(
      id: order.id,
      idempotencyKey: order.idempotencyKey,
      tempNumber: order.tempNumber,
      paymentMethod: Value(order.paymentMethod),
      discountVnd: Value(order.discountVnd),
      totalVnd: order.totalVnd,
      createdAt: order.createdAtUtc,
      devicePrefix: order.devicePrefix,
    ),
  );

  @override
  Future<void> insertOrderItem(NewOrderItem item) => _db.insertOrderItem(
    OrderItemsCompanion.insert(
      id: item.id,
      orderId: item.orderId,
      productId: item.productId,
      nameSnapshot: item.nameSnapshot,
      unitPriceVnd: item.unitPriceVnd,
      quantity: item.quantity,
      lineDiscountVnd: Value(item.lineDiscountVnd),
      lineTotalVnd: item.lineTotalVnd,
    ),
  );

  @override
  Future<void> insertOutbox(NewOutboxEntry entry) async {
    await _db.insertOutboxEntry(
      OutboxCompanion.insert(
        idempotencyKey: entry.idempotencyKey,
        payloadJson: entry.payloadJson,
        state: OutboxState.pending.dbValue,
        createdAt: entry.createdAtUtc,
        updatedAt: entry.createdAtUtc,
      ),
    );
  }
}
