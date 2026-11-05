import 'package:flutter/foundation.dart';

/// Khớp schema DailyProfit trong api/openapi.yaml.
/// Tiền là int VND. [profitVnd] có thể âm (lỗ).
@immutable
class DailyProfit {
  const DailyProfit({
    required this.date,
    required this.revenueVnd,
    required this.expenseVnd,
    required this.profitVnd,
  });

  factory DailyProfit.fromJson(Map<String, dynamic> json) {
    return DailyProfit(
      date: json['date'] as String,
      revenueVnd: (json['revenue_vnd'] as num).toInt(),
      expenseVnd: (json['expense_vnd'] as num).toInt(),
      profitVnd: (json['profit_vnd'] as num).toInt(),
    );
  }

  final String date;
  final int revenueVnd;
  final int expenseVnd;
  final int profitVnd;

  bool get isLoss => profitVnd < 0;
}
