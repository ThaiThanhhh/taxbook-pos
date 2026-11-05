import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/features/reports/data/reports_providers.dart';
import 'package:dt13_pos/features/reports/domain/top_product.dart';
import 'package:dt13_pos/features/reports/presentation/top_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final from = DateTime(2026, 11);
  final to = DateTime(2026, 11, 5);

  Widget createWidgetUnderTest(Override override) {
    return ProviderScope(
      retry: (count, error) => null,
      overrides: [override],
      child: MaterialApp(
        home: TopProductsScreen(
          initialRange: DateTimeRange(start: from, end: to),
        ),
      ),
    );
  }

  testWidgets('Hiển thị danh sách sản phẩm bán chạy', (tester) async {
    const products = [
      TopProduct(
        productId: 'p-1',
        name: 'Trà sữa',
        qty: 50,
        revenueVnd: 1500000,
      ),
    ];

    await tester.pumpWidget(
      createWidgetUnderTest(
        topProductsProvider(
          from: from,
          to: to,
        ).overrideWith((ref) async => products),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sản phẩm bán chạy'), findsOneWidget);
    expect(find.text('Trà sữa'), findsOneWidget);
    expect(find.text('Đã bán: 50'), findsOneWidget);
    expect(find.text('1.500.000 ₫'), findsOneWidget);
  });

  testWidgets('Hiển thị EmptyState khi danh sách rỗng', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        topProductsProvider(
          from: from,
          to: to,
        ).overrideWith((ref) async => <TopProduct>[]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('Hiển thị ErrorState khi có lỗi', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        topProductsProvider(from: from, to: to).overrideWith(
          (ref) => Future<List<TopProduct>>.error(Exception('Lỗi mạng')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
