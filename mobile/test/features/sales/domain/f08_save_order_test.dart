import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:dt13_pos/core/db/app_database.dart';
import 'package:dt13_pos/core/db/db_values.dart';
import 'package:dt13_pos/core/db/drift_order_write_dao.dart';
import 'package:dt13_pos/core/ports/clock.dart';
import 'package:dt13_pos/core/ports/order_write_dao.dart';
import 'package:dt13_pos/core/utils/uuid_v7_id_generator.dart';
import 'package:dt13_pos/core/utils/vn_time.dart';
import 'package:dt13_pos/features/sales/domain/cart_calc.dart';
import 'package:dt13_pos/features/sales/domain/save_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đồng hồ chỉnh tay trong test.
final class _FakeClock implements Clock {
  _FakeClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}

/// C1: 10:00 giờ Việt Nam ngày 13/11/2026.
DateTime _c1() => DateTime.utc(2026, 11, 13, 3);

/// C2: 10:00 giờ Việt Nam ngày 14/11/2026.
DateTime _c2() => DateTime.utc(2026, 11, 14, 3);

const _comSuon = CartLine(
  productId: 'com-suon',
  name: 'Cơm sườn',
  unitPriceVnd: 45000,
  quantity: 1,
);

/// Bọc DAO thật để đếm transaction, chặn cổng và ném lỗi đúng chỗ.
final class _ProbeDao implements OrderWriteDao {
  _ProbeDao(this._inner);

  final OrderWriteDao _inner;
  int transactions = 0;

  /// Nếu có, transaction đứng chờ cổng này trước khi chạy.
  Completer<void>? gate;

  /// Ném ngay trước khi ghi outbox (sau khi đã ghi orders và order_items).
  bool failOnOutbox = false;

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    transactions++;
    final pending = gate;
    if (pending != null) await pending.future;
    return _inner.transaction(action);
  }

  @override
  Future<int> nextDaySeq({
    required String devicePrefix,
    required String dayKey,
  }) => _inner.nextDaySeq(devicePrefix: devicePrefix, dayKey: dayKey);

  @override
  Future<void> insertOrder(NewOrder order) => _inner.insertOrder(order);

  @override
  Future<void> insertOrderItem(NewOrderItem item) =>
      _inner.insertOrderItem(item);

  @override
  Future<void> insertOutbox(NewOutboxEntry entry) {
    if (failOnOutbox) throw StateError('disk full');
    return _inner.insertOutbox(entry);
  }
}

Future<AppDatabase> _openDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await db.open();
  return db;
}

SaveOrder _saveOrder(_ProbeDao dao, Clock clock) => SaveOrder(
  dao: dao,
  clock: clock,
  ids: UuidV7IdGenerator(clock),
  devicePrefix: 'A1',
);

Future<SavedOrder> _saveCash(SaveOrder save, [List<CartLine>? lines]) => save(
  lines ?? const [_comSuon],
  orderDiscountBp: 0,
  paymentMethod: PaymentMethod.cash,
);

Future<int> _count(AppDatabase db, TableInfo<Table, Object?> table) async =>
    (await db.select(table).get()).length;

void main() {
  test('f08_two_orders', () async {
    final db = await _openDb();
    final clock = _FakeClock(_c1());
    final save = _saveOrder(_ProbeDao(DriftOrderWriteDao(db)), clock);

    final first = await _saveCash(save);
    final second = await _saveCash(save);

    expect(first.tempNumber, 'A1-261113-0001');
    expect(second.tempNumber, 'A1-261113-0002');
    expect(first.idempotencyKey, isNot(second.idempotencyKey));
    // Ký tự version của UUID (ký tự thứ 15, sau hai dấu '-') là '7'.
    expect(first.idempotencyKey[14], '7');
    expect(second.idempotencyKey[14], '7');
    // Variant RFC: 8, 9, a hoặc b.
    expect('89ab', contains(first.idempotencyKey[19]));

    final orders = await db.select(db.orders).get();
    expect(orders.map((o) => o.tempNumber), [
      'A1-261113-0001',
      'A1-261113-0002',
    ]);
    expect(orders.map((o) => o.devicePrefix), everyElement('A1'));
    expect(orders.map((o) => o.paymentMethod), everyElement('cash'));
    expect(orders.map((o) => o.totalVnd), everyElement(45000));
    expect(await _count(db, db.orderItems), 2);

    // Mỗi đơn có đúng một mục outbox cùng key, trạng thái pending.
    final outbox = await db.select(db.outbox).get();
    expect(outbox.map((o) => o.idempotencyKey), [
      first.idempotencyKey,
      second.idempotencyKey,
    ]);
    expect(outbox.map((o) => o.state), everyElement('pending'));
    expect(
      orders.map((o) => o.idempotencyKey),
      outbox.map((o) => o.idempotencyKey),
    );
  });

  test('f08_new_day_new_counter', () async {
    final db = await _openDb();
    final clock = _FakeClock(_c1());
    final save = _saveOrder(_ProbeDao(DriftOrderWriteDao(db)), clock);

    await _saveCash(save);
    await _saveCash(save);
    clock.now = _c2();
    final third = await _saveCash(save);

    expect(third.tempNumber, 'A1-261114-0001');
    final counters = await (db.select(
      db.deviceCounters,
    )..orderBy([(c) => OrderingTerm.asc(c.dayKey)])).get();
    // Seq của ngày cũ không bị sửa.
    expect(counters.map((c) => (c.devicePrefix, c.dayKey, c.seq)).toList(), [
      ('A1', '261113', 2),
      ('A1', '261114', 1),
    ]);
  });

  test('f08_day_key_uses_vietnam_time', () async {
    // 17:30 UTC ngày 13 đã là 00:30 ngày 14 ở Việt Nam.
    expect(vnDayKey(DateTime.utc(2026, 11, 13, 17, 30)), '261114');
    expect(vnDayKey(DateTime.utc(2026, 11, 13, 16, 59, 59)), '261113');
    expect(vnDayKey(DateTime.utc(2026, 12, 31, 17)), '270101');

    final db = await _openDb();
    final clock = _FakeClock(DateTime.utc(2026, 11, 13, 17, 30));
    final saved = await _saveCash(
      _saveOrder(_ProbeDao(DriftOrderWriteDao(db)), clock),
    );
    expect(saved.tempNumber, 'A1-261114-0001');
    // created_at vẫn lưu UTC.
    final row = await db.select(db.orders).getSingle();
    expect(row.createdAt, '2026-11-13T17:30:00.000Z');
  });

  test('f08_rollback', () async {
    final db = await _openDb();
    final dao = _ProbeDao(DriftOrderWriteDao(db))..failOnOutbox = true;
    final save = _saveOrder(dao, _FakeClock(_c1()));

    await expectLater(_saveCash(save), throwsStateError);

    expect(await _count(db, db.orders), 0);
    expect(await _count(db, db.orderItems), 0);
    expect(await _count(db, db.outbox), 0);
    // Seq không tăng: không có hàng bộ đếm nào còn lại.
    expect(await _count(db, db.deviceCounters), 0);

    // Lưu lại sau lỗi: vẫn nhận số 0001, và có thể lưu lần nữa.
    dao.failOnOutbox = false;
    final retry = await _saveCash(save);
    expect(retry.tempNumber, 'A1-261113-0001');
    expect(await _count(db, db.orders), 1);
    expect(await _count(db, db.outbox), 1);
  });

  test('f08_rollback_keeps_existing_seq', () async {
    final db = await _openDb();
    final dao = _ProbeDao(DriftOrderWriteDao(db));
    final save = _saveOrder(dao, _FakeClock(_c1()));
    await _saveCash(save);

    dao.failOnOutbox = true;
    await expectLater(_saveCash(save), throwsStateError);

    final counter = await db.select(db.deviceCounters).getSingle();
    expect(counter.seq, 1);
    expect(await _count(db, db.orders), 1);
    expect(await _count(db, db.outbox), 1);
  });

  test('f08_snapshot', () async {
    final db = await _openDb();
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            id: 'com-suon',
            name: 'Cơm sườn',
            unitPriceVnd: 45000,
            unitLabel: 'phần',
            updatedAt: '2026-11-13T00:00:00.000Z',
          ),
        );
    final save = _saveOrder(
      _ProbeDao(DriftOrderWriteDao(db)),
      _FakeClock(_c1()),
    );

    await _saveCash(save);
    await (db.update(db.products)..where((p) => p.id.equals('com-suon'))).write(
      const ProductsCompanion(unitPriceVnd: Value(99999)),
    );

    final item = await db.select(db.orderItems).getSingle();
    expect(item.unitPriceVnd, 45000);
    expect(item.nameSnapshot, 'Cơm sườn');
    final outbox = await db.select(db.outbox).getSingle();
    final payload = jsonDecode(outbox.payloadJson) as Map<String, Object?>;
    final items = payload['items']! as List<Object?>;
    expect((items.single! as Map<String, Object?>)['unit_price_vnd'], 45000);
  });

  test('f08_payload_matches_order_create', () async {
    final db = await _openDb();
    final save = _saveOrder(
      _ProbeDao(DriftOrderWriteDao(db)),
      _FakeClock(_c1()),
    );
    const traDa = CartLine(
      productId: 'tra-da',
      name: 'Trà đá',
      unitPriceVnd: 5000,
      quantity: 2,
    );

    final saved = await save(
      const [_comSuon, traDa],
      // 10% cả đơn trên 55.000 = 5.500.
      orderDiscountBp: 1000,
      paymentMethod: PaymentMethod.cash,
    );

    final outbox = await db.select(db.outbox).getSingle();
    expect(outbox.payloadJson, saved.payloadJson);
    final payload = jsonDecode(outbox.payloadJson) as Map<String, Object?>;
    expect(payload.keys.toSet(), {
      'temp_number',
      'items',
      'discount_vnd',
      'payment_method',
      'created_at',
    });
    expect(payload['temp_number'], 'A1-261113-0001');
    expect(payload['discount_vnd'], 5500);
    expect(payload['payment_method'], 'cash');
    expect(payload['created_at'], '2026-11-13T03:00:00.000Z');
    final items = (payload['items']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(items, [
      {'product_id': 'com-suon', 'quantity': 1, 'unit_price_vnd': 45000},
      {'product_id': 'tra-da', 'quantity': 2, 'unit_price_vnd': 5000},
    ]);
    for (final item in items) {
      expect(item.keys.toSet(), {'product_id', 'quantity', 'unit_price_vnd'});
    }

    final order = await db.select(db.orders).getSingle();
    expect(order.discountVnd, 5500);
    expect(order.totalVnd, 49500);
    expect(saved.totalVnd, 49500);
    expect(order.createdAt, '2026-11-13T03:00:00.000Z');
  });

  test('f08_line_discount_is_part_of_order_discount', () async {
    final db = await _openDb();
    final save = _saveOrder(
      _ProbeDao(DriftOrderWriteDao(db)),
      _FakeClock(_c1()),
    );
    const discounted = CartLine(
      productId: 'com-suon',
      name: 'Cơm sườn',
      unitPriceVnd: 45000,
      quantity: 2,
      lineDiscountBp: 1000,
    );

    await save(
      const [discounted],
      orderDiscountBp: 0,
      paymentMethod: PaymentMethod.cash,
    );

    final order = await db.select(db.orders).getSingle();
    final item = await db.select(db.orderItems).getSingle();
    expect(item.lineDiscountVnd, 9000);
    expect(item.lineTotalVnd, 81000);
    expect(item.unitPriceVnd, 45000);
    expect(order.discountVnd, 9000);
    expect(order.totalVnd, 81000);
    expect(
      order.totalVnd,
      item.unitPriceVnd * item.quantity - order.discountVnd,
    );
  });

  test('f08_invalid_cart_opens_no_transaction', () async {
    final db = await _openDb();
    final dao = _ProbeDao(DriftOrderWriteDao(db));
    final save = _saveOrder(dao, _FakeClock(_c1()));

    await expectLater(_saveCash(save, const []), throwsA(CartError.empty));

    expect(dao.transactions, 0);
    expect(await _count(db, db.orders), 0);
    // Lỗi giỏ không làm kẹt chốt chống bấm đôi.
    expect((await _saveCash(save)).tempNumber, 'A1-261113-0001');
  });

  test('f08_double_tap_one_transaction', () async {
    final db = await _openDb();
    final dao = _ProbeDao(DriftOrderWriteDao(db))..gate = Completer<void>();
    final save = _saveOrder(dao, _FakeClock(_c1()));

    final first = _saveCash(save);
    final second = _saveCash(save);
    final third = _saveCash(save);
    dao.gate!.complete();
    final results = await Future.wait([first, second, third]);

    expect(dao.transactions, 1);
    expect(await _count(db, db.orders), 1);
    expect(await _count(db, db.outbox), 1);
    // Lần bấm chồng nhận lại đúng đơn đang lưu, không sinh key khác.
    expect(results[1].idempotencyKey, results[0].idempotencyKey);
    expect(results[2].tempNumber, 'A1-261113-0001');

    // Xong rồi thì lần bấm sau là đơn mới.
    dao.gate = null;
    final next = await _saveCash(save);
    expect(dao.transactions, 2);
    expect(next.tempNumber, 'A1-261113-0002');
  });

  test('f08_failed_save_releases_double_tap_guard', () async {
    final db = await _openDb();
    final dao = _ProbeDao(DriftOrderWriteDao(db))..failOnOutbox = true;
    final save = _saveOrder(dao, _FakeClock(_c1()));

    await expectLater(_saveCash(save), throwsStateError);
    dao.failOnOutbox = false;

    expect((await _saveCash(save)).tempNumber, 'A1-261113-0001');
    expect(dao.transactions, 2);
  });

  test('f08_uuid_v7_generator_uses_clock_time', () {
    final clock = _FakeClock(DateTime.utc(2026, 11, 13, 3));
    final id = UuidV7IdGenerator(clock).newId();

    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    // 48 bit đầu là mili-giây Unix lấy từ Clock.
    final millis = int.parse(
      id.replaceAll('-', '').substring(0, 12),
      radix: 16,
    );
    expect(millis, clock.now.millisecondsSinceEpoch);
  });

  test('f08_migrate_v1_counter_to_per_day', () async {
    // DB v1: khóa chính chỉ có device_prefix, đang giữ seq của một ngày.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE device_counters ('
              'device_prefix TEXT NOT NULL, day_key TEXT NOT NULL, '
              'seq INTEGER NOT NULL, PRIMARY KEY (device_prefix))',
            )
            ..execute("INSERT INTO device_counters VALUES ('A1', '261113', 7)")
            ..execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);
    await db.open();

    final kept = await db.select(db.deviceCounters).getSingle();
    expect((kept.devicePrefix, kept.dayKey, kept.seq), ('A1', '261113', 7));

    // Sau nâng cấp, ngày mới có hàng riêng, ngày cũ không bị sửa.
    final dao = DriftOrderWriteDao(db);
    expect(await dao.nextDaySeq(devicePrefix: 'A1', dayKey: '261114'), 1);
    expect(await dao.nextDaySeq(devicePrefix: 'A1', dayKey: '261113'), 8);
    final all = await (db.select(
      db.deviceCounters,
    )..orderBy([(c) => OrderingTerm.asc(c.dayKey)])).get();
    expect(all.map((c) => (c.dayKey, c.seq)).toList(), [
      ('261113', 8),
      ('261114', 1),
    ]);
  });

  test('f08_no_network_import', () {
    final source = File(
      'lib/features/sales/domain/save_order.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();

    expect(imports, isNotEmpty);
    for (final uri in imports) {
      expect(uri, isNot(contains('dio')), reason: uri);
      expect(uri, isNot(contains('api_client')), reason: uri);
      expect(uri, isNot(contains('network')), reason: uri);
      expect(uri, isNot(startsWith('package:flutter/')), reason: uri);
      expect(uri, isNot(startsWith('package:drift/')), reason: uri);
      expect(uri, isNot(startsWith('dart:io')), reason: uri);
      expect(uri, isNot(startsWith('dart:ui')), reason: uri);
      // Không import feature khác: chỉ được trỏ vào domain của chính sales.
      if (uri.contains('/features/')) {
        expect(
          uri,
          startsWith('package:dt13_pos/features/sales/domain/'),
          reason: uri,
        );
      }
    }
    expect(source, isNot(contains('DateTime.now')));
  });
}
