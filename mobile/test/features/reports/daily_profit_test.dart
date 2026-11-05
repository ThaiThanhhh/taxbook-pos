import 'package:dt13_pos/features/reports/domain/daily_profit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyProfit Unit Tests', () {
    test('fromJson đọc đúng tên trường snake_case của hợp đồng', () {
      final profit = DailyProfit.fromJson(const {
        'date': '2026-11-05',
        'revenue_vnd': 1500000,
        'expense_vnd': 900000,
        'profit_vnd': 600000,
      });
      expect(profit.profitVnd, 600000);
      expect(profit.isLoss, isFalse);
    });

    test('lãi âm được nhận diện là lỗ', () {
      final profit = DailyProfit.fromJson(const {
        'date': '2026-11-05',
        'revenue_vnd': 100000,
        'expense_vnd': 300000,
        'profit_vnd': -200000,
      });
      expect(profit.isLoss, isTrue);
    });
  });
}
