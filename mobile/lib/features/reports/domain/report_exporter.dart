import 'package:dt13_pos/features/reports/domain/report_models.dart';
import 'package:intl/intl.dart';

abstract final class ReportExporter {
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _csvDate = DateFormat('yyyy-MM-dd');
  static final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

  static String formatDailyProfitText(DailyProfit profit) {
    final result = StringBuffer()
      ..writeln('BÁO CÁO LÃI/LỖ TRONG NGÀY')
      ..writeln('Ngày: ${_displayDate.format(profit.date)}')
      ..writeln('Tổng doanh thu: ${_formatVnd(profit.revenueVnd)}')
      ..writeln('Tổng chi phí: ${_formatVnd(profit.expenseVnd)}')
      ..write(
        '${profit.profitVnd < 0 ? 'Lỗ' : 'Lãi'} trong ngày: '
        '${_formatVnd(profit.profitVnd)}',
      );
    return result.toString();
  }

  static String formatDailyProfitCsv(DailyProfit profit) {
    final status = profit.profitVnd < 0 ? 'loss' : 'profit';
    return [
      'date,revenue_vnd,expense_vnd,profit_vnd,status',
      '${_csvDate.format(profit.date)},${profit.revenueVnd},'
          '${profit.expenseVnd},${profit.profitVnd},$status',
    ].join('\n');
  }

  static String formatTopProductsText(
    List<TopProduct> products, {
    required DateTime from,
    required DateTime to,
  }) {
    final result = StringBuffer()
      ..writeln('BÁO CÁO SẢN PHẨM BÁN CHẠY')
      ..writeln(
        'Thời gian: ${_displayDate.format(from)} - ${_displayDate.format(to)}',
      );
    if (products.isEmpty) {
      result.write('Không có sản phẩm bán trong khoảng thời gian này.');
      return result.toString();
    }

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      result
        ..writeln()
        ..writeln('${index + 1}. ${product.name}')
        ..writeln('   Số lượng đã bán: ${product.qty}')
        ..write('   Doanh thu: ${_formatVnd(product.revenueVnd)}');
      if (index < products.length - 1) result.writeln();
    }
    return result.toString();
  }

  static String formatTopProductsCsv(List<TopProduct> products) {
    final rows = <String>['rank,product_id,name,qty,revenue_vnd'];
    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      rows.add(
        '${index + 1},${_escapeCsv(product.productId)},'
        '${_escapeCsv(product.name)},${product.qty},${product.revenueVnd}',
      );
    }
    return rows.join('\n');
  }

  static String _formatVnd(int amount) {
    final sign = amount < 0 ? '-' : '';
    return '$sign${_vnd.format(amount.abs())} ₫';
  }

  static String _escapeCsv(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n') &&
        !value.contains('\r')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
