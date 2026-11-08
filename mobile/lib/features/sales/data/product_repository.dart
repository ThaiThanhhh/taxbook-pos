import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:dt13_pos/core/db/app_database.dart';
import 'package:dt13_pos/core/ports/clock.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:flutter/services.dart';

/// Kho sản phẩm local. Chỉ lớp data biết Flutter asset và drift.
final class ProductRepository implements ProductCatalog {
  ProductRepository({
    required this._database,
    required this._clock,
    AssetBundle? assetBundle,
  }) : _assetBundle = assetBundle ?? rootBundle;

  static const String comTamAssetPath = 'assets/seed/com_tam.json';

  final AppDatabase _database;
  final Clock _clock;
  final AssetBundle _assetBundle;

  /// Đọc, kiểm tra toàn bộ asset trước khi bắt đầu transaction.
  ///
  /// Id giữ nguyên từ JSON. Upsert theo khóa chính nên gọi lại không nhân đôi;
  /// không xóa các sản phẩm khác trong DB. Mọi lỗi được truyền cho người gọi.
  Future<void> seedFromAsset({String assetPath = comTamAssetPath}) async {
    final source = await _assetBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(source);
    final updatedAt = _clock.nowUtc().toUtc().toIso8601String();
    final rows = _parseProducts(decoded, updatedAt: updatedAt);

    // Chỉ await thao tác DB trong transaction, không đọc asset hay gọi Clock.
    await _database.transaction(() async {
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(_database.products, rows);
      });
    });
  }

  /// Có món nào trong bảng chưa (kể cả món đã tắt).
  Future<bool> hasAnyProduct() async {
    final row =
        await (_database.selectOnly(_database.products)
              ..addColumns([_database.products.id])
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Món đang bán (`is_active = 1`), theo thứ tự nạp vào DB (rowid). Upsert
  /// giữ nguyên rowid nên seed lại không xáo thứ tự lưới.
  @override
  Future<List<Product>> listForSale() async {
    final query = _database.select(_database.products)
      ..where((p) => p.isActive.equals(1))
      ..orderBy([(p) => OrderingTerm.asc(p.rowId)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        Product(
          id: row.id,
          name: row.name,
          unitPriceVnd: row.unitPriceVnd,
          unitLabel: row.unitLabel,
        ),
    ];
  }
}

List<ProductsCompanion> _parseProducts(
  Object? decoded, {
  required String updatedAt,
}) {
  if (decoded is! List<Object?> || decoded.isEmpty) {
    throw const FormatException('Danh sách món phải là một mảng không rỗng.');
  }

  final ids = <String>{};
  final rows = <ProductsCompanion>[];
  for (var index = 0; index < decoded.length; index++) {
    final item = decoded[index];
    if (item is! Map<String, Object?>) {
      throw FormatException('Món ở dòng ${index + 1} phải là một đối tượng.');
    }

    final id = _requiredString(item, 'id', index);
    final name = _requiredString(item, 'name', index);
    final unitLabel = _requiredString(item, 'unit_label', index);
    final price = item['unit_price_vnd'];
    if (price is! int || price < 1) {
      throw FormatException(
        'Giá món ở dòng ${index + 1} phải là số nguyên lớn hơn 0.',
      );
    }
    if (!ids.add(id)) {
      throw FormatException('Mã món bị trùng ở dòng ${index + 1}.');
    }

    rows.add(
      ProductsCompanion.insert(
        id: id,
        name: name,
        unitPriceVnd: price,
        unitLabel: unitLabel,
        isActive: const Value(1),
        updatedAt: updatedAt,
      ),
    );
  }
  return rows;
}

String _requiredString(Map<String, Object?> item, String field, int index) {
  final value = item[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Trường $field ở dòng ${index + 1} phải là chuỗi không rỗng.',
    );
  }
  return value;
}
