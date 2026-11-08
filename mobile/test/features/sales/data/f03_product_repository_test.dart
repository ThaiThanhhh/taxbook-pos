import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:dt13_pos/core/db/app_database.dart';
import 'package:dt13_pos/core/ports/clock.dart';
import 'package:dt13_pos/features/sales/data/product_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 11, 5, 5, 0);
}

final class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('F03 không được tạo HTTP client');
  }
}

Future<T> _withoutNetwork<T>(Future<T> Function() body) {
  return HttpOverrides.runZoned(
    () => IOOverrides.runZoned(
      body,
      socketConnect: (host, port, {sourceAddress, sourcePort = 0, timeout}) =>
          throw StateError('F03 không được mở kết nối mạng'),
      socketStartConnect: (host, port, {sourceAddress, sourcePort = 0}) =>
          throw StateError('F03 không được mở kết nối mạng'),
    ),
    createHttpClient: _NoNetworkHttpOverrides().createHttpClient,
  );
}

/// Bundle trong bộ nhớ cho ca JSON lỗi, không đụng asset thật.
final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw StateError('Không có asset $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

Future<AppDatabase> _openMemoryDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await db.open();
  return db;
}

ProductRepository _repo(AppDatabase db, {AssetBundle? bundle}) =>
    ProductRepository(
      database: db,
      clock: const _FixedClock(),
      assetBundle: bundle ?? rootBundle,
    );

Future<int> _count(AppDatabase db) async =>
    (await db.select(db.products).get()).length;

Future<int> _price(AppDatabase db, String id) async => (await (db.select(
  db.products,
)..where((p) => p.id.equals(id))).getSingle()).unitPriceVnd;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('f03_count', () async {
    final db = await _openMemoryDb();
    await _repo(db).seedFromAsset();

    expect(await _count(db), 24);
  });

  test('f03_price', () async {
    final db = await _openMemoryDb();
    await _repo(db).seedFromAsset();

    expect(await _price(db, 'com-suon'), 45000);
    expect(await _price(db, 'khan'), 2000);
    expect(await _price(db, 'com-dac-biet'), 65000);
  });

  test('f03_sum', () async {
    final db = await _openMemoryDb();
    await _repo(db).seedFromAsset();

    final row = await db
        .customSelect('SELECT SUM(unit_price_vnd) AS total FROM products')
        .getSingle();
    expect(row.read<int>('total'), 539000);
  });

  test('f03_twice', () async {
    final db = await _openMemoryDb();
    await db.insertOrder(
      OrdersCompanion.insert(
        id: 'order-f03-sentinel',
        idempotencyKey: '019a0000-0000-7000-8000-000000000003',
        tempNumber: 'TEST-261105-1',
        totalVnd: 45000,
        createdAt: '2026-11-05T05:00:00.000Z',
        devicePrefix: 'TEST',
      ),
    );
    final orderBefore = await db.select(db.orders).getSingle();
    for (final operation in ['INSERT', 'UPDATE', 'DELETE']) {
      await db.customStatement('''
        CREATE TRIGGER guard_orders_${operation.toLowerCase()}
        BEFORE $operation ON orders
        BEGIN
          SELECT RAISE(ABORT, 'seed must not write orders');
        END
      ''');
    }

    final repo = _repo(db);
    await repo.seedFromAsset();
    await repo.seedFromAsset();

    expect(await _count(db), 24);
    expect(await _price(db, 'com-suon'), 45000);
    expect(await db.select(db.orders).getSingle(), orderBefore);
  });

  test('f03_bad_json', () async {
    final db = await _openMemoryDb();
    final source = await rootBundle.loadString(
      ProductRepository.comTamAssetPath,
    );
    final items = (jsonDecode(source) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(Map<String, Object?>.of)
        .toList();
    expect(items, hasLength(24));
    items.last['unit_price_vnd'] = '45000';
    final bundle = _MemoryAssetBundle({
      ProductRepository.comTamAssetPath: jsonEncode(items),
    });

    await expectLater(
      _repo(db, bundle: bundle).seedFromAsset(),
      throwsA(isA<FormatException>()),
    );
    expect(await _count(db), 0);
  });

  test('f03_without_network', () async {
    await _withoutNetwork(() async {
      // Chứng minh chốt chặn thực sự có hiệu lực trước khi gọi repository.
      expect(HttpClient.new, throwsStateError);
      expect(() => Socket.connect('127.0.0.1', 9), throwsStateError);
      expect(() => Socket.startConnect('127.0.0.1', 9), throwsStateError);

      final db = await _openMemoryDb();
      final assetBundle = PlatformAssetBundle();
      final repo = _repo(db, bundle: assetBundle);
      await repo.seedFromAsset();
      await repo.seedFromAsset();
      expect(await _count(db), 24);
      final row = await db
          .customSelect('SELECT SUM(unit_price_vnd) AS total FROM products')
          .getSingle();
      expect(row.read<int>('total'), 539000);
    });
  });

  // Ca bổ sung: lỗi ở món sau không để lại món trước.
  test('f03_missing_field_rejects_whole_seed', () async {
    final db = await _openMemoryDb();
    final bundle = _MemoryAssetBundle({
      ProductRepository.comTamAssetPath:
          '[{"id":"com-suon","name":"Cơm sườn","unit_price_vnd":45000,'
          '"unit_label":"phần"},'
          '{"id":"khan","name":"Khăn lạnh","unit_price_vnd":2000}]',
    });

    await expectLater(
      _repo(db, bundle: bundle).seedFromAsset(),
      throwsA(isA<FormatException>()),
    );
    expect(await _count(db), 0);
  });

  test('f03_rejects_missing_or_invalid_fields', () async {
    final db = await _openMemoryDb();
    final valid = <String, Object?>{
      'id': 'com-suon',
      'name': 'Cơm sườn',
      'unit_price_vnd': 45000,
      'unit_label': 'phần',
    };
    final invalid = <Map<String, Object?>>[
      for (final key in valid.keys) Map<String, Object?>.of(valid)..remove(key),
      {...valid, 'unit_price_vnd': 45000.0},
      {...valid, 'unit_price_vnd': true},
      {...valid, 'unit_price_vnd': null},
      {...valid, 'unit_price_vnd': 0},
      {...valid, 'unit_price_vnd': -1},
      {...valid, 'id': ''},
      {...valid, 'name': '   '},
      {...valid, 'unit_label': 1},
    ];
    for (final item in invalid) {
      final bundle = _MemoryAssetBundle({
        ProductRepository.comTamAssetPath: jsonEncode([item]),
      });
      await expectLater(
        _repo(db, bundle: bundle).seedFromAsset(),
        throwsA(isA<FormatException>()),
      );
      expect(await _count(db), 0);
    }
  });

  test('f03_rejects_malformed_or_duplicate_json', () async {
    final db = await _openMemoryDb();
    for (final source in [
      '{',
      '{}',
      '[]',
      '[null]',
      '[{"id":"x","name":"X","unit_price_vnd":1,"unit_label":"cái"},'
          '{"id":"x","name":"X","unit_price_vnd":1,"unit_label":"cái"}]',
    ]) {
      final bundle = _MemoryAssetBundle({
        ProductRepository.comTamAssetPath: source,
      });
      await expectLater(
        _repo(db, bundle: bundle).seedFromAsset(),
        throwsA(isA<FormatException>()),
      );
      expect(await _count(db), 0);
    }
  });

  test('f03_db_failure_rolls_back_whole_seed', () async {
    final db = await _openMemoryDb();
    // Khăn nằm sau nhiều món: lỗi tại đây phải rollback cả những dòng trước.
    await db.customStatement('''
      CREATE TRIGGER reject_seed_khan BEFORE INSERT ON products
      WHEN NEW.id = 'khan'
      BEGIN
        SELECT RAISE(ABORT, 'test seed failure');
      END
    ''');

    await expectLater(_repo(db).seedFromAsset(), throwsA(isA<Exception>()));
    expect(await _count(db), 0);
  });

  test('f03_reseed_updates_by_id_preserves_other_products', () async {
    final db = await _openMemoryDb();
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            id: 'mon-rieng',
            name: 'Món riêng',
            unitPriceVnd: 1000,
            unitLabel: 'phần',
            updatedAt: '2026-11-05T00:00:00.000Z',
          ),
        );
    final repo = _repo(db);
    await repo.seedFromAsset();
    await (db.update(db.products)..where((p) => p.id.equals('com-suon'))).write(
      const ProductsCompanion(unitPriceVnd: Value(1)),
    );
    await repo.seedFromAsset();
    expect(await _count(db), 25);
    expect(await _price(db, 'com-suon'), 45000);
    expect(await _price(db, 'mon-rieng'), 1000);
  });

  test('f03_fixture_ids_units_and_no_fake_item', () async {
    final db = await _openMemoryDb();
    await _repo(db).seedFromAsset();

    final rows = await (db.select(
      db.products,
    )..orderBy([(p) => OrderingTerm(expression: p.rowId)])).get();
    expect(rows.first.id, 'com-suon');
    expect(rows.last.id, 'nuoc-sam');
    expect(
      [
        for (final r in rows) [r.id, r.name, r.unitPriceVnd, r.unitLabel],
      ],
      const [
        ['com-suon', 'Cơm sườn', 45000, 'phần'],
        ['com-suon-bi', 'Cơm sườn bì', 50000, 'phần'],
        ['com-suon-cha', 'Cơm sườn chả', 50000, 'phần'],
        ['com-dac-biet', 'Cơm đặc biệt', 65000, 'phần'],
        ['suon-them', 'Sườn thêm', 25000, 'phần'],
        ['cha-them', 'Chả thêm', 15000, 'phần'],
        ['trung', 'Trứng ốp la', 10000, 'quả'],
        ['bi-them', 'Bì thêm', 10000, 'phần'],
        ['canh', 'Canh rau', 10000, 'tô'],
        ['tra-da', 'Trà đá', 5000, 'ly'],
        ['tra-tac', 'Trà tắc', 15000, 'ly'],
        ['nuoc-mia', 'Nước mía', 15000, 'ly'],
        ['sua-dau', 'Sữa đậu nành', 10000, 'ly'],
        ['suoi', 'Nước suối', 8000, 'chai'],
        ['sting', 'Sting', 12000, 'chai'],
        ['coca', 'Coca', 15000, 'lon'],
        ['khan', 'Khăn lạnh', 2000, 'cái'],
        ['com-it', 'Cơm thêm', 5000, 'phần'],
        ['com-cha', 'Cơm chả', 40000, 'phần'],
        ['com-bi', 'Cơm bì', 35000, 'phần'],
        ['com-trung', 'Cơm sườn trứng', 55000, 'phần'],
        ['nuoc-ngot', 'Nước ngọt khác', 12000, 'lon'],
        ['dau-hu', 'Đậu hũ', 20000, 'phần'],
        ['nuoc-sam', 'Nước sâm', 10000, 'ly'],
      ],
    );
    expect(rows.map((r) => r.id), isNot(contains('mo-hanh')));
    expect(rows.map((r) => r.unitPriceVnd), everyElement(greaterThan(0)));
    expect(rows.singleWhere((r) => r.id == 'com-trung').name, 'Cơm sườn trứng');
    expect(rows.singleWhere((r) => r.id == 'trung').unitLabel, 'quả');
    expect(rows.first.updatedAt, '2026-11-05T05:00:00.000Z');
  });
}
