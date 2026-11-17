class DailyProfit {
  const DailyProfit({
    required this.date,
    required this.revenueVnd,
    required this.expenseVnd,
    required this.profitVnd,
  });

  factory DailyProfit.fromJson(Map<String, Object?> json) {
    return DailyProfit(
      date: _parseDate(json['date'], 'date'),
      revenueVnd: _parseInt(json['revenue_vnd'], 'revenue_vnd'),
      expenseVnd: _parseInt(json['expense_vnd'], 'expense_vnd'),
      profitVnd: _parseInt(json['profit_vnd'], 'profit_vnd'),
    );
  }

  final DateTime date;
  final int revenueVnd;
  final int expenseVnd;
  final int profitVnd;
}

class TopProduct {
  const TopProduct({
    required this.productId,
    required this.name,
    required this.qty,
    required this.revenueVnd,
  });

  factory TopProduct.fromJson(Map<String, Object?> json) {
    return TopProduct(
      productId: _parseString(json['product_id'], 'product_id'),
      name: _parseString(json['name'], 'name'),
      qty: _parseInt(json['qty'], 'qty'),
      revenueVnd: _parseInt(json['revenue_vnd'], 'revenue_vnd'),
    );
  }

  final String productId;
  final String name;
  final int qty;
  final int revenueVnd;
}

DateTime _parseDate(Object? value, String field) {
  if (value is String) {
    final date = DateTime.tryParse(value);
    if (date != null) return date;
  }
  throw FormatException('Trường "$field" không phải ngày hợp lệ.');
}

int _parseInt(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('Trường "$field" không phải số nguyên.');
}

String _parseString(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('Trường "$field" không phải chuỗi.');
}
