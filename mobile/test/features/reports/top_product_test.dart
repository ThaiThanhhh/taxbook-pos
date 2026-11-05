import 'package:dt13_pos/features/reports/domain/top_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TopProduct.fromJson đọc đúng tên trường của hợp đồng', () {
    final product = TopProduct.fromJson(const {
      'product_id': 'p-001',
      'name': 'Cà phê sữa',
      'qty': 120,
      'revenue_vnd': 3600000,
    });
    expect(product.productId, 'p-001');
    expect(product.name, 'Cà phê sữa');
    expect(product.qty, 120);
    expect(product.revenueVnd, 3600000);
  });
}
