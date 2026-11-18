/// Món bán trên màn hình bán hàng. Dart thuần: không Flutter, không drift.
library;

/// Một món trong danh mục. Giá là `int` VND.
final class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unitPriceVnd,
    required this.unitLabel,
  });

  final String id;
  final String name;
  final int unitPriceVnd;
  final String unitLabel;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.unitPriceVnd == unitPriceVnd &&
      other.unitLabel == unitLabel;

  @override
  int get hashCode => Object.hash(id, name, unitPriceVnd, unitLabel);

  @override
  String toString() => 'Product($id, $name, $unitPriceVnd/$unitLabel)';
}

/// Nguồn danh mục món cho màn bán. Data layer implement, test dùng bản giả.
abstract interface class ProductCatalog {
  /// Các món đang bán, theo thứ tự hiện trên lưới. Lỗi đọc DB được ném ra.
  Future<List<Product>> listForSale();
}
