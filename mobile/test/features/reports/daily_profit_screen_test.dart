import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/features/reports/data/report_providers.dart';
import 'package:dt13_pos/features/reports/data/report_repository.dart';
import 'package:dt13_pos/features/reports/domain/report_models.dart';
import 'package:dt13_pos/features/reports/presentation/daily_profit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Xuất báo cáo mở sheet và sao chép CSV được', (tester) async {
    final copiedTexts = _mockClipboard();
    addTearDown(_clearClipboardMock);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(
            _FakeReportRepository(
              profit: DailyProfit(
                date: DateTime(2026, 1, 2),
                revenueVnd: 1250000,
                expenseVnd: 250000,
                profitVnd: 1000000,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DailyProfitScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xuất báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Xuất báo cáo lãi/lỗ'), findsOneWidget);
    expect(find.text('Bản tóm tắt'), findsOneWidget);

    await tester.tap(find.text('Dữ liệu CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sao chép nội dung báo cáo'));
    await tester.pumpAndSettle();

    expect(copiedTexts, [
      'date,revenue_vnd,expense_vnd,profit_vnd,status\n'
          '2026-01-02,1250000,250000,1000000,profit',
    ]);
    expect(find.text('Đã sao chép báo cáo vào bộ nhớ tạm'), findsOneWidget);
  });
}

List<String> _mockClipboard() {
  final copiedTexts = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedTexts.add(arguments['text']! as String);
        }
        return null;
      });
  return copiedTexts;
}

void _clearClipboardMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null);
}

class _FakeReportRepository implements ReportRepository {
  _FakeReportRepository({required this.profit});

  final DailyProfit profit;

  @override
  Future<DailyProfit> fetchDailyProfit(DateTime date) async => profit;

  @override
  Future<List<TopProduct>> fetchTopProducts({
    required DateTime from,
    required DateTime to,
  }) async => const [];
}
