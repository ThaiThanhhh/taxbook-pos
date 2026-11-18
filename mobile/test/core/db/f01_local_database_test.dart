import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:dt13_pos/core/db/app_database.dart';
import 'package:dt13_pos/core/db/db_values.dart';
import 'package:flutter_test/flutter_test.dart';

const _createdAt = '2026-11-04T04:30:00.000Z';

/// Key giả theo dạng UUID v7, đổi [n] để không trùng UNIQUE.
String _key(int n) =>
    '019a0000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

OrdersCompanion _order(
  int n, {
  int totalVnd = 45000,
  String? idempotencyKey,
  Value<String?> paymentMethod = const Value.absent(),
}) => OrdersCompanion.insert(
  id: 'ord-$n',
  idempotencyKey: idempotencyKey ?? _key(n),
  tempNumber: 'A-20261104-${n.toString().padLeft(4, '0')}',
  paymentMethod: paymentMethod,
  totalVnd: totalVnd,
  createdAt: _createdAt,
  devicePrefix: 'A',
);

OutboxCompanion _outbox(int n, {required String state}) =>
    OutboxCompanion.insert(
      idempotencyKey: _key(n),
      payloadJson: '{"orderId":"ord-$n"}',
      state: state,
      createdAt: _createdAt,
      updatedAt: _createdAt,
    );

Future<AppDatabase> _openMemoryDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await db.open();
  return db;
}

Future<int> _count(AppDatabase db, TableInfo<Table, Object?> table) async =>
    (await db.select(table).get()).length;

void main() {
  test('f01_roundtrip', () async {
    // Dùng file thật vì DB in-memory mất khi đóng, không kiểm được "mở lại".
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'f01_roundtrip_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    addTearDown(() {
      for (final suffix in ['', '-wal', '-shm']) {
        final side = File('${file.path}$suffix');
        if (side.existsSync()) side.deleteSync();
      }
    });

    final db = AppDatabase(NativeDatabase(file));
    try {
      await db.open();
      await db.transaction(() async {
        await db.insertOrder(_order(1));
        await db.insertOrderItem(
          OrderItemsCompanion.insert(
            id: 'itm-1',
            orderId: 'ord-1',
            productId: 'prd-com-suon',
            nameSnapshot: 'Cơm sườn',
            unitPriceVnd: 45000,
            quantity: 1,
            lineTotalVnd: 45000,
          ),
        );
        await db.insertOutboxEntry(
          _outbox(1, state: OutboxState.pending.dbValue),
        );
      });
    } finally {
      await db.close();
    }

    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);

    final order = await reopened.select(reopened.orders).getSingle();
    final item = await reopened.select(reopened.orderItems).getSingle();
    final outbox = await reopened.select(reopened.outbox).getSingle();

    expect(order.totalVnd, 45000);
    expect(item.nameSnapshot, 'Cơm sườn');
    expect(outbox.state, OutboxState.pending.dbValue);
  });

  test('f01_rollback', () async {
    final db = await _openMemoryDb();

    await expectLater(
      db.transaction(() async {
        await db.insertOrder(_order(2));
        throw Exception('mất điện trước khi ghi outbox');
      }),
      throwsA(isA<Exception>()),
    );

    expect(await _count(db, db.orders), 0);
    expect(await _count(db, db.outbox), 0);
  });

  test('f01_reject_bad_state', () async {
    final db = await _openMemoryDb();

    await expectLater(
      db.insertOutboxEntry(_outbox(3, state: 'synced')),
      throwsA(isA<InvalidDbValueException>()),
    );

    expect(await _count(db, db.outbox), 0);
  });

  test('f01_check_constraint_blocks_raw_insert', () async {
    final db = await _openMemoryDb();

    // Bỏ qua hàm insert* có kiểm tra, ghi thẳng: CHECK constraint vẫn chặn.
    await expectLater(
      db.into(db.outbox).insert(_outbox(4, state: 'synced')),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.into(db.orders).insert(_order(4, paymentMethod: const Value('momo'))),
      throwsA(isA<SqliteException>()),
    );

    expect(await _count(db, db.outbox), 0);
    expect(await _count(db, db.orders), 0);
  });

  test('f01_payment_method_whitelist', () async {
    final db = await _openMemoryDb();

    await expectLater(
      db.insertOrder(_order(5, paymentMethod: const Value('card'))),
      throwsA(isA<InvalidDbValueException>()),
    );

    const allowed = <String?>[null, 'cash', 'bank_qr'];
    for (final (i, method) in allowed.indexed) {
      await db.insertOrder(_order(100 + i, paymentMethod: Value(method)));
    }

    final rows = await db.select(db.orders).get();
    expect(rows.map((r) => r.paymentMethod), unorderedEquals(allowed));
  });

  test('f01_idempotency_key_unique', () async {
    final db = await _openMemoryDb();

    await db.insertOrder(_order(6, idempotencyKey: _key(6)));
    await expectLater(
      db.insertOrder(_order(7, idempotencyKey: _key(6))),
      throwsA(isA<SqliteException>()),
    );

    expect(await _count(db, db.orders), 1);
  });

  test('f01_order_item_requires_existing_order', () async {
    final db = await _openMemoryDb();

    // PRAGMA foreign_keys = ON: dòng hàng mồ côi (không có đơn) bị chặn.
    await expectLater(
      db.insertOrderItem(
        OrderItemsCompanion.insert(
          id: 'itm-orphan',
          orderId: 'ord-khong-ton-tai',
          productId: 'prd-1',
          nameSnapshot: 'Trà đá',
          unitPriceVnd: 5000,
          quantity: 1,
          lineTotalVnd: 5000,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );

    expect(await _count(db, db.orderItems), 0);
  });

  test('f01_schema_money_columns_are_integer', () async {
    final db = await _openMemoryDb();

    const moneyColumns = {
      'products': ['unit_price_vnd'],
      'orders': ['discount_vnd', 'total_vnd'],
      'order_items': ['unit_price_vnd', 'line_discount_vnd', 'line_total_vnd'],
    };
    for (final MapEntry(key: table, value: columns) in moneyColumns.entries) {
      final info = await db.customSelect('PRAGMA table_info($table)').get();
      final types = {
        for (final r in info) r.read<String>('name'): r.read<String>('type'),
      };
      for (final col in columns) {
        expect(types[col], 'INTEGER', reason: '$table.$col');
      }
      expect(types.values, isNot(contains('REAL')), reason: table);
    }
  });

  test('f01_indexes_exist', () async {
    final db = await _openMemoryDb();

    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();

    expect(
      rows.map((r) => r.read<String>('name')),
      containsAll(const [
        'idx_orders_created_at',
        'idx_outbox_state_created_at',
        'idx_order_items_order_id',
      ]),
    );
  });

  test('f01_db_values_pure_dart', () {
    expect(OutboxState.dbValues, const [
      'pending',
      'sending',
      'done',
      'failed_retryable',
      'failed_permanent',
    ]);
    expect(PaymentMethod.dbValues, const ['cash', 'bank_qr']);
    expect(OutboxState.fromDb('failed_retryable'), OutboxState.failedRetryable);
    expect(PaymentMethod.fromDb('bank_qr'), PaymentMethod.bankQr);
    expect(PaymentMethod.fromDb(null), isNull);
    expect(
      () => OutboxState.fromDb('synced'),
      throwsA(isA<InvalidDbValueException>()),
    );
    expect(
      () => requireValidPaymentMethod('momo'),
      throwsA(isA<InvalidDbValueException>()),
    );
  });
}
