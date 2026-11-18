import 'dart:async';

import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:dt13_pos/features/sales/data/product_catalog_provider.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:dt13_pos/features/sales/presentation/sales_screen.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cart_bar.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cart_panel.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/product_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture: 3 món lấy theo đúng giá của com_tam.json.
const _fixture = <Product>[
  Product(
    id: 'com-suon',
    name: 'Cơm sườn',
    unitPriceVnd: 45000,
    unitLabel: 'phần',
  ),
  Product(id: 'tra-da', name: 'Trà đá', unitPriceVnd: 5000, unitLabel: 'ly'),
  Product(
    id: 'com-dac-biet',
    name: 'Cơm đặc biệt',
    unitPriceVnd: 65000,
    unitLabel: 'phần',
  ),
];

/// Catalog giả: mỗi lần gọi lấy kết quả từ [onCall] và đếm số lần gọi.
final class _FakeCatalog implements ProductCatalog {
  _FakeCatalog(this.onCall);

  final Future<List<Product>> Function(int call) onCall;
  int calls = 0;

  @override
  Future<List<Product>> listForSale() {
    calls++;
    return onCall(calls);
  }
}

Future<void> _pumpSales(WidgetTester tester, _FakeCatalog catalog) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [productCatalogProvider.overrideWithValue(catalog)],
      child: MaterialApp(theme: AppTheme.light(), home: const SalesScreen()),
    ),
  );
}

Finder _tile(String productId) => find.byKey(ValueKey(productId));

Finder _inCartBar(Finder matching) =>
    find.descendant(of: find.byType(CartBar), matching: matching);

void main() {
  testWidgets('f06_tap', (tester) async {
    final catalog = _FakeCatalog((_) async => _fixture);
    await _pumpSales(tester, catalog);
    await tester.pumpAndSettle();

    expect(find.byType(ProductTile), findsNWidgets(_fixture.length));
    expect(_inCartBar(find.text('0 món')), findsOneWidget);

    await tester.tap(_tile('com-suon'));
    await tester.pump();

    expect(_inCartBar(find.text('1 món')), findsOneWidget);
    expect(_inCartBar(find.textContaining('45.000')), findsOneWidget);
    expect(catalog.calls, 1);
  });

  testWidgets('f06_tap_twice_counts_two_lines', (tester) async {
    await _pumpSales(tester, _FakeCatalog((_) async => _fixture));
    await tester.pumpAndSettle();

    await tester.tap(_tile('com-suon'));
    await tester.tap(_tile('tra-da'));
    await tester.pump();

    expect(_inCartBar(find.text('2 món')), findsOneWidget);
    expect(_inCartBar(find.text(MoneyFormat.format(50000))), findsOneWidget);
  });

  testWidgets('f06_empty', (tester) async {
    await _pumpSales(tester, _FakeCatalog((_) async => const []));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Chưa có món'), findsOneWidget);
    expect(find.byType(ProductTile), findsNothing);
    expect(find.byType(CartBar), findsNothing);
    expect(find.text('Đang bán trên máy'), findsOneWidget);
  });

  testWidgets('f06_error', (tester) async {
    final catalog = _FakeCatalog((call) async {
      if (call == 1) {
        throw StateError('database is locked');
      }
      return _fixture;
    });
    await _pumpSales(tester, catalog);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(ProductTile), findsNothing);
    expect(find.text('Đang bán trên máy'), findsOneWidget);
    // Không lộ chi tiết lỗi kỹ thuật ra màn hình.
    expect(find.textContaining('database is locked'), findsNothing);
    expect(catalog.calls, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(catalog.calls, 2);
    expect(find.byType(ErrorState), findsNothing);
    expect(find.byType(ProductTile), findsNWidgets(_fixture.length));
  });

  testWidgets('f06_error_no_auto_retry', (tester) async {
    final catalog = _FakeCatalog((_) async => throw StateError('io'));
    await _pumpSales(tester, catalog);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));

    expect(catalog.calls, 1);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('f06_loading', (tester) async {
    final pending = Completer<List<Product>>();
    await _pumpSales(tester, _FakeCatalog((_) => pending.future));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ProductTile), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(CartBar), findsNothing);
    expect(find.text('Đang bán trên máy'), findsOneWidget);

    pending.complete(_fixture);
    await tester.pumpAndSettle();
    expect(find.byType(ProductTile), findsNWidgets(_fixture.length));
  });

  testWidgets('f06_pay_shows_not_saved', (tester) async {
    await _pumpSales(tester, _FakeCatalog((_) async => _fixture));
    await tester.pumpAndSettle();

    final payButton = find.widgetWithText(FilledButton, 'Thu tiền');
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);

    await tester.tap(_tile('com-suon'));
    await tester.pump();
    expect(tester.getSize(payButton).height, AppSpacing.buttonHeightLarge);

    await tester.tap(payButton);
    await tester.pump();
    expect(find.text('Chưa lưu được'), findsOneWidget);
  });

  testWidgets('f06_tile_size_and_text', (tester) async {
    await _pumpSales(tester, _FakeCatalog((_) async => _fixture));
    await tester.pumpAndSettle();

    final tileSize = tester.getSize(_tile('com-suon'));
    expect(tileSize.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    expect(tileSize.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));

    final name = tester.widget<Text>(
      find.descendant(of: _tile('com-suon'), matching: find.text('Cơm sườn')),
    );
    expect(name.style!.fontSize, greaterThanOrEqualTo(16));

    final banner = tester.widget<Text>(find.text('Đang bán trên máy'));
    expect(banner.style!.fontSize, greaterThanOrEqualTo(16));
    expect(find.textContaining('Chờ gửi'), findsNothing);
  });

  testWidgets('f06_large_text_no_overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productCatalogProvider.overrideWithValue(
            _FakeCatalog((_) async => _fixture),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const SalesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProductTile), findsWidgets);
  });

  testWidgets('f06_grid_scrolls_with_keyboard_and_large_text', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final products = List<Product>.generate(
      24,
      (index) => Product(
        id: 'mon-$index',
        name: 'Món $index',
        unitPriceVnd: 10000 + index,
        unitLabel: 'phần',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productCatalogProvider.overrideWithValue(
            _FakeCatalog((_) async => products),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const SalesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mon-0')));
    await tester.pump();
    await tester.tap(find.byTooltip(CartPanel.expandTooltip));
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    final grid = find.byKey(SalesScreen.productGridKey);
    expect(tester.getSize(grid).height, greaterThan(0));
    await tester.scrollUntilVisible(
      find.text('Món 23'),
      100,
      maxScrolls: 100,
      scrollable: find.descendant(of: grid, matching: find.byType(Scrollable)),
    );
    expect(find.text('Món 23').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('f06_grid_scrolls_with_cart_open', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final products = List<Product>.generate(
      24,
      (index) => Product(
        id: 'mon-$index',
        name: 'Món $index',
        unitPriceVnd: 10000 + index,
        unitLabel: 'phần',
      ),
    );
    await _pumpSales(tester, _FakeCatalog((_) async => products));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mon-0')));
    await tester.pump();

    final grid = find.byKey(SalesScreen.productGridKey);
    final scrollable = find.descendant(
      of: grid,
      matching: find.byType(Scrollable),
    );
    for (final expanded in [false, true]) {
      if (expanded) {
        await tester.tap(find.byTooltip(CartPanel.expandTooltip));
        await tester.pump();
      }
      expect(tester.getSize(grid).height, greaterThan(100));
      await tester.scrollUntilVisible(
        find.text('Món 23'),
        200,
        scrollable: scrollable,
      );
      expect(find.text('Món 23').hitTestable(), findsOneWidget);
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.pixels, greaterThan(0));
      await tester.scrollUntilVisible(
        find.text('Món 0'),
        -200,
        scrollable: scrollable,
      );
      expect(find.text('Món 0').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
