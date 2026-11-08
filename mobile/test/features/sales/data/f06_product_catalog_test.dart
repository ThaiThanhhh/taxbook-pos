import 'package:drift/native.dart';
import 'package:dt13_pos/core/db/app_database.dart';
import 'package:dt13_pos/core/ports/clock.dart';
import 'package:dt13_pos/features/sales/data/product_catalog_provider.dart';
import 'package:dt13_pos/features/sales/data/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 11, 5, 5, 0);
}

Future<ProductRepository> _repo() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await db.open();
  return ProductRepository(database: db, clock: const _FixedClock());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('f06_list_for_sale_keeps_seed_order', () async {
    final repo = await _repo();
    expect(await repo.hasAnyProduct(), isFalse);

    await repo.seedFromAsset();
    final products = await repo.listForSale();

    expect(await repo.hasAnyProduct(), isTrue);
    expect(products, hasLength(24));
    expect(products.first.id, 'com-suon');
    expect(products.first.name, 'Cơm sườn');
    expect(products.first.unitPriceVnd, 45000);
    expect(products.last.id, 'nuoc-sam');
  });

  test('f06_seed_if_empty_dev', () async {
    final repo = await _repo();
    final catalog = SeedIfEmptyCatalog(repo, seedIfEmpty: true);

    expect(await catalog.listForSale(), hasLength(24));
    // Gọi lại (bấm Thử lại) không nhân đôi món.
    expect(await catalog.listForSale(), hasLength(24));
  });

  test('f06_no_seed_prod', () async {
    final repo = await _repo();
    final catalog = SeedIfEmptyCatalog(repo, seedIfEmpty: false);

    expect(await catalog.listForSale(), isEmpty);
    expect(await repo.hasAnyProduct(), isFalse);
  });
}
