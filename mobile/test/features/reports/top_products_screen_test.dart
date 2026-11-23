import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/features/reports/data/report_providers.dart';
import 'package:dt13_pos/features/reports/data/report_repository.dart';
import 'package:dt13_pos/features/reports/domain/report_models.dart';
import 'package:dt13_pos/features/reports/presentation/top_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Xuất báo cáo mở sheet và sao chép nội dung tóm tắt được', (
    tester,
  ) async {
    final copiedTexts = _mockClipboard();
    addTearDown(_clearClipboardMock);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(
            _FakeReportRepository(
              products: const [
                TopProduct(
                  productId: 'p-1',
                  name: 'Cà phê',
                  qty: 12,
                  revenueVnd: 600000,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const TopProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xuất báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Xuất báo cáo sản phẩm bán chạy'), findsOneWidget);
    await tester.tap(find.text('Sao chép nội dung báo cáo'));
    await tester.pumpAndSettle();

    expect(copiedTexts, hasLength(1));
    expect(copiedTexts.single, contains('1. Cà phê'));
    expect(copiedTexts.single, contains('Số lượng đã bán: 12'));
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
  _FakeReportRepository({required this.products});

  final List<TopProduct> products;

  @override
  Future<DailyProfit> fetchDailyProfit(DateTime date) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TopProduct>> fetchTopProducts({
    required DateTime from,
    required DateTime to,
  }) async => products;
}
