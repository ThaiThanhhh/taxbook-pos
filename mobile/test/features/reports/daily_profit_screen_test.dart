import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/features/reports/data/reports_providers.dart';
import 'package:dt13_pos/features/reports/domain/daily_profit.dart';
import 'package:dt13_pos/features/reports/presentation/daily_profit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testDate = DateTime(2026, 11, 5);

  Widget createWidgetUnderTest(Override override) {
    return ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [override],
      child: MaterialApp(home: DailyProfitScreen(initialDate: testDate)),
    );
  }

  testWidgets('Hiển thị dữ liệu báo cáo thành công', (tester) async {
    const profitData = DailyProfit(
      date: '2026-11-05',
      revenueVnd: 1500000,
      expenseVnd: 900000,
      profitVnd: 600000,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        dailyProfitProvider(testDate).overrideWith((ref) async => profitData),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Báo cáo ngày'), findsOneWidget);
    expect(find.text('Tổng doanh thu'), findsOneWidget);
    expect(find.text('Tổng chi phí'), findsOneWidget);
    expect(find.text('Lãi trong ngày'), findsOneWidget);
    expect(find.text('600.000 ₫'), findsOneWidget);
  });

  testWidgets('Hiển thị nhãn Lỗ khi lãi âm', (tester) async {
    const profitData = DailyProfit(
      date: '2026-11-05',
      revenueVnd: 100000,
      expenseVnd: 300000,
      profitVnd: -200000,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        dailyProfitProvider(testDate).overrideWith((ref) async => profitData),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lỗ trong ngày'), findsOneWidget);
    expect(find.text('-200.000 ₫'), findsOneWidget);
  });

  testWidgets('Hiển thị EmptyState khi không có giao dịch', (tester) async {
    const profitData = DailyProfit(
      date: '2026-11-05',
      revenueVnd: 0,
      expenseVnd: 0,
      profitVnd: 0,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        dailyProfitProvider(testDate).overrideWith((ref) async => profitData),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Chưa có giao dịch'), findsOneWidget);
  });

  testWidgets('Hiển thị ErrorState khi có lỗi', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        dailyProfitProvider(testDate).overrideWith(
          (ref) => Future<DailyProfit>.error(Exception('Lỗi mạng')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(
      find.text('Không tải được báo cáo. Vui lòng thử lại.'),
      findsOneWidget,
    );
  });
}
