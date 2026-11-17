import 'package:dt13_pos/features/reports/domain/report_exporter.dart';
import 'package:dt13_pos/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyProfit export', () {
    final profit = DailyProfit(
      date: DateTime(2026, 1, 2),
      revenueVnd: 1250000,
      expenseVnd: 250000,
      profitVnd: 1000000,
    );

    test('định dạng bản tóm tắt và CSV khi có lãi', () {
      expect(
        ReportExporter.formatDailyProfitText(profit),
        'BÁO CÁO LÃI/LỖ TRONG NGÀY\n'
        'Ngày: 02/01/2026\n'
        'Tổng doanh thu: 1.250.000 ₫\n'
        'Tổng chi phí: 250.000 ₫\n'
        'Lãi trong ngày: 1.000.000 ₫',
      );
      expect(
        ReportExporter.formatDailyProfitCsv(profit),
        'date,revenue_vnd,expense_vnd,profit_vnd,status\n'
        '2026-01-02,1250000,250000,1000000,profit',
      );
    });

    test('định dạng khoản lỗ có dấu âm trong bản tóm tắt và CSV', () {
      final loss = DailyProfit(
        date: profit.date,
        revenueVnd: 100000,
        expenseVnd: 350000,
        profitVnd: -250000,
      );

      expect(
        ReportExporter.formatDailyProfitText(loss),
        contains('Lỗ trong ngày: -250.000 ₫'),
      );
      expect(
        ReportExporter.formatDailyProfitCsv(loss),
        endsWith('2026-01-02,100000,350000,-250000,loss'),
      );
    });
  });

  test('định dạng danh sách sản phẩm bán chạy dạng text và CSV', () {
    const products = [
      TopProduct(productId: 'p-1', name: 'Cà phê', qty: 12, revenueVnd: 600000),
      TopProduct(
        productId: 'p,2',
        name: 'Trà "đặc biệt"',
        qty: 4,
        revenueVnd: 320000,
      ),
    ];

    expect(
      ReportExporter.formatTopProductsText(
        products,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      ),
      'BÁO CÁO SẢN PHẨM BÁN CHẠY\n'
      'Thời gian: 01/01/2026 - 31/01/2026\n'
      '\n'
      '1. Cà phê\n'
      '   Số lượng đã bán: 12\n'
      '   Doanh thu: 600.000 ₫\n'
      '\n'
      '2. Trà "đặc biệt"\n'
      '   Số lượng đã bán: 4\n'
      '   Doanh thu: 320.000 ₫',
    );
    expect(
      ReportExporter.formatTopProductsCsv(products),
      'rank,product_id,name,qty,revenue_vnd\n'
      '1,p-1,Cà phê,12,600000\n'
      '2,"p,2","Trà ""đặc biệt""",4,320000',
    );
  });
}
