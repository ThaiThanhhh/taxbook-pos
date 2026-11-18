import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:dt13_pos/features/sales/data/product_catalog_provider.dart';
import 'package:dt13_pos/features/sales/domain/cart_calc.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:dt13_pos/features/sales/presentation/cart_notifier.dart';
import 'package:dt13_pos/features/sales/presentation/sales_screen.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cart_bar.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cart_line_tile.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cart_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture: giá theo com_tam.json.
const _fixture = <Product>[
  Product(
    id: 'com-suon',
    name: 'Cơm sườn',
    unitPriceVnd: 45000,
    unitLabel: 'phần',
  ),
  Product(id: 'tra-da', name: 'Trà đá', unitPriceVnd: 5000, unitLabel: 'ly'),
];

final class _FakeCatalog implements ProductCatalog {
  @override
  Future<List<Product>> listForSale() async => _fixture;
}

/// Bơm màn bán; trả container để đọc state giỏ.
Future<ProviderContainer> _pumpSales(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [productCatalogProvider.overrideWithValue(_FakeCatalog())],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light(), home: const SalesScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _product(String id) => find.byKey(ValueKey(id));

Finder _inCartBar(Finder matching) =>
    find.descendant(of: find.byType(CartBar), matching: matching);

Finder _lineTile(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(CartLineTile));

Finder _stepIn(String name, String tooltip) =>
    find.descendant(of: _lineTile(name), matching: find.byTooltip(tooltip));

Finder get _discountInput => find.descendant(
  of: find.byKey(CartPanel.discountFieldKey),
  matching: find.byType(EditableText),
);

String _discountText(WidgetTester tester) =>
    tester.widget<EditableText>(_discountInput).controller.text;

Future<void> _showLines(WidgetTester tester) async {
  if (find.byKey(CartPanel.lineListKey).evaluate().isEmpty) {
    await tester.tap(find.byTooltip(CartPanel.expandTooltip));
    await tester.pump();
  }
}

Future<void> _enterDiscount(WidgetTester tester, String text) async {
  await _showLines(tester);
  await tester.scrollUntilVisible(
    _discountInput,
    100,
    scrollable: find
        .descendant(
          of: find.byKey(CartPanel.lineListKey),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.enterText(_discountInput, text);
  await tester.pump();
}

Future<void> _tapStep(WidgetTester tester, String name, String tooltip) async {
  await _showLines(tester);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final list = find.byKey(CartPanel.lineListKey);
  final button = _stepIn(name, tooltip);
  for (var attempt = 0; attempt < 20; attempt++) {
    if (button.hitTestable().evaluate().isNotEmpty) break;
    await tester.drag(list, const Offset(0, 100));
    await tester.pumpAndSettle();
  }
  expect(button.hitTestable(), findsOneWidget);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('f07_double', (tester) async {
    final container = await _pumpSales(tester);

    await tester.tap(_product('com-suon'));
    await tester.pump();
    await _tapStep(tester, 'Cơm sườn', CartLineTile.incrementTooltip);
    await tester.pump();

    final cart = container.read(cartProvider);
    expect(cart.lines.single.quantity, 2);
    final expected = calcCart(
      cart.lines,
      orderDiscountBp: cart.orderDiscountBp,
    ).totalVnd;
    expect(expected, 90000);
    expect(cart.totals.totalVnd, expected);
    expect(_inCartBar(find.text(MoneyFormat.format(expected))), findsOneWidget);
    expect(_inCartBar(find.text('90.000 ₫')), findsOneWidget);
    // Thành tiền của dòng cũng hiện 90.000 ₫, căn phải.
    expect(
      find.descendant(
        of: _lineTile('Cơm sườn'),
        matching: find.text('90.000 ₫'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('f07_discount_field', (tester) async {
    final container = await _pumpSales(tester);

    await tester.tap(_product('com-suon'));
    await tester.tap(_product('tra-da'));
    await tester.pump();
    expect(container.read(cartProvider).totals.subtotalVnd, 50000);

    await _enterDiscount(tester, '5000');
    await tester.pump();

    expect(_discountText(tester), '5.000');
    final cart = container.read(cartProvider);
    expect(cart.orderDiscountBp, 1000);
    expect(cart.totals.totalVnd, 45000);
    expect(_inCartBar(find.text('45.000 ₫')), findsOneWidget);
  });

  testWidgets('f07_letter', (tester) async {
    final container = await _pumpSales(tester);
    await tester.tap(_product('com-suon'));
    await tester.pump();

    await _enterDiscount(tester, 'a');
    await tester.pump();
    expect(_discountText(tester), isEmpty);
    expect(container.read(cartProvider).orderDiscountBp, 0);

    await _enterDiscount(tester, '5a');
    await tester.pump();
    expect(_discountText(tester), '5');
    expect(_discountText(tester), isNot(contains('a')));
  });

  testWidgets('f07_discount_over_subtotal_not_clamped', (tester) async {
    final container = await _pumpSales(tester);
    await tester.tap(_product('tra-da'));
    await tester.pump();

    await _enterDiscount(tester, '6000');
    await tester.pump();

    expect(find.text(CartPanel.overSubtotalError), findsOneWidget);
    final cart = container.read(cartProvider);
    // Không kẹp về 100%: bỏ giảm cho tới khi người bán sửa số.
    expect(cart.orderDiscountBp, 0);
    expect(cart.orderDiscountRejected, isTrue);
    expect(cart.totals.totalVnd, 5000);
    final payButton = find.widgetWithText(FilledButton, 'Thu tiền');
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);

    // Thêm cơm sườn -> tạm tính 50.000, số 6.000 trở thành hợp lệ.
    await tester.tap(_product('com-suon'));
    await tester.pump();
    expect(find.text(CartPanel.overSubtotalError), findsNothing);
    final after = container.read(cartProvider);
    expect(after.orderDiscountRejected, isFalse);
    expect(after.orderDiscountBp, _vndToBp(6000, 50000));
    expect(after.totals.totalVnd, 50000 - 50000 * 1200 ~/ 10000);
    expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);
  });

  testWidgets('f07_pay_disabled_when_subtotal_drops_below_discount', (
    tester,
  ) async {
    final container = await _pumpSales(tester);
    await tester.tap(_product('com-suon'));
    await tester.tap(_product('tra-da'));
    await tester.pump();
    await _enterDiscount(tester, '10000');
    await tester.pump();

    await _showLines(tester);
    final payButton = find.widgetWithText(FilledButton, 'Thu tiền');
    expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);

    // Bớt cơm sườn: tạm tính còn 5.000, số giảm 10.000 không còn hợp lệ.
    await _tapStep(tester, 'Cơm sườn', CartLineTile.decrementTooltip);
    await tester.pump();

    final cart = container.read(cartProvider);
    expect(cart.orderDiscountRejected, isTrue);
    expect(cart.totals.totalVnd, 5000);
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);
    await tester.tap(payButton);
    await tester.pump();
    expect(find.text(CartBar.notSavedMessage), findsNothing);
  });

  testWidgets('f07_discount_follows_subtotal', (tester) async {
    final container = await _pumpSales(tester);
    await tester.tap(_product('com-suon'));
    await tester.tap(_product('tra-da'));
    await tester.pump();
    await _enterDiscount(tester, '5000');
    await tester.pump();

    await _showLines(tester);
    // Cơm sườn thành 2 -> tạm tính 95.000, vẫn giảm theo 5.000 đ đã nhập.
    await _tapStep(tester, 'Cơm sườn', CartLineTile.incrementTooltip);
    await tester.pump();
    final cart = container.read(cartProvider);
    expect(cart.totals.subtotalVnd, 95000);
    expect(cart.orderDiscountBp, 5000 * 10000 ~/ 95000);
    expect(
      cart.totals,
      calcCart(cart.lines, orderDiscountBp: cart.orderDiscountBp),
    );
  });

  testWidgets('f07_decrement_to_zero_clears_discount', (tester) async {
    final container = await _pumpSales(tester);
    await tester.tap(_product('com-suon'));
    await tester.pump();
    await _enterDiscount(tester, '5000');
    await tester.pump();

    await _showLines(tester);
    await _tapStep(tester, 'Cơm sườn', CartLineTile.decrementTooltip);
    await tester.pump();

    final cart = container.read(cartProvider);
    expect(cart.isEmpty, isTrue);
    expect(cart.orderDiscountBp, 0);
    expect(find.byType(CartLineTile), findsNothing);
    expect(_inCartBar(find.text('0 món')), findsOneWidget);

    // Thêm lại: ô giảm trống, không mang số cũ sang đơn mới.
    await tester.tap(_product('com-suon'));
    await tester.pump();
    await _enterDiscount(tester, '');
    expect(_discountText(tester), isEmpty);
    expect(container.read(cartProvider).totals.totalVnd, 45000);
  });

  testWidgets('f07_list_is_builder_and_tap_targets', (tester) async {
    await _pumpSales(tester);
    await tester.tap(_product('com-suon'));
    await tester.tap(_product('tra-da'));
    await tester.pump();
    await _showLines(tester);

    final list = tester.widget<ListView>(
      find.descendant(
        of: find.byType(CartPanel),
        matching: find.byType(ListView),
      ),
    );
    expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
    expect(find.byType(CartLineTile), findsNWidgets(2));

    for (final tooltip in [
      CartLineTile.incrementTooltip,
      CartLineTile.decrementTooltip,
    ]) {
      final size = tester.getSize(
        find.ancestor(
          of: _stepIn('Cơm sườn', tooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    }

    final name = tester.widget<Text>(
      find.descendant(
        of: _lineTile('Cơm sườn'),
        matching: find.text('Cơm sườn'),
      ),
    );
    expect(name.style!.fontSize, greaterThanOrEqualTo(16));

    // Thành tiền nằm bên phải tên món.
    final nameRight = tester.getTopRight(
      find.descendant(
        of: _lineTile('Cơm sườn'),
        matching: find.text('Cơm sườn'),
      ),
    );
    final moneyLeft = tester.getTopLeft(
      find.descendant(
        of: _lineTile('Cơm sườn'),
        matching: find.text('45.000 ₫'),
      ),
    );
    expect(moneyLeft.dx, greaterThan(nameRight.dx));

    // Nút Thu tiền vẫn cao 52 khi có khung giỏ.
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Thu tiền')).height,
      AppSpacing.buttonHeightLarge,
    );
  });

  testWidgets('f07_many_lines_scroll_no_overflow', (tester) async {
    await _pumpSales(tester);
    for (var i = 0; i < 15; i++) {
      await tester.tap(_product('tra-da'));
    }
    await tester.pump();
    await _showLines(tester);

    expect(tester.takeException(), isNull);
    // ListView.builder chỉ dựng các dòng đang thấy, không dựng đủ 15.
    expect(find.byType(CartLineTile).evaluate().length, lessThan(15));
    expect(_inCartBar(find.text('15 món')), findsOneWidget);
  });

  testWidgets('f07_selected_count_and_collapse', (tester) async {
    await _pumpSales(tester);
    await tester.tap(_product('com-suon'));
    await tester.pump();
    expect(find.text(CartPanel.selectedLabel(1)), findsOneWidget);
    expect(find.byType(CartLineTile), findsNothing);

    await _tapStep(tester, 'Cơm sườn', CartLineTile.incrementTooltip);
    await tester.pump();

    expect(find.text(CartPanel.selectedLabel(2)), findsOneWidget);
    expect(find.byType(CartLineTile), findsOneWidget);

    await tester.tap(find.byTooltip(CartPanel.collapseTooltip));
    await tester.pump();

    expect(find.byType(CartLineTile), findsNothing);
    expect(find.byKey(CartPanel.lineListKey), findsNothing);
    expect(find.text(CartPanel.selectedLabel(2)), findsOneWidget);
    expect(find.byKey(CartPanel.discountFieldKey), findsNothing);
    expect(
      tester.getSize(find.byTooltip(CartPanel.expandTooltip)).height,
      greaterThanOrEqualTo(AppSpacing.minTapTarget),
    );

    await tester.tap(find.byTooltip(CartPanel.expandTooltip));
    await tester.pump();
    expect(find.byType(CartLineTile), findsOneWidget);
  });

  testWidgets('f07_collapse_keeps_discount_and_payment_guard', (tester) async {
    final container = await _pumpSales(tester);
    await tester.tap(_product('com-suon'));
    await tester.pump();
    await _enterDiscount(tester, '5000');

    final payButton = find.widgetWithText(FilledButton, 'Thu tiền');
    final validTotal = container.read(cartProvider).totals;
    await tester.tap(find.byTooltip(CartPanel.collapseTooltip));
    await tester.pump();
    expect(find.byKey(CartPanel.discountFieldKey), findsNothing);
    expect(container.read(cartProvider).totals, validTotal);
    expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);

    await _showLines(tester);
    await tester.scrollUntilVisible(
      _discountInput,
      100,
      scrollable: find
          .descendant(
            of: find.byKey(CartPanel.lineListKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(_discountText(tester), '5.000');
    await _enterDiscount(tester, '60000');
    await tester.tap(find.byTooltip(CartPanel.collapseTooltip));
    await tester.pump();
    expect(find.text(CartPanel.overSubtotalError), findsOneWidget);
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);
    expect(container.read(cartProvider).orderDiscountRejected, isTrue);
  });

  testWidgets('f07_expanded_list_scrolls', (tester) async {
    await _pumpSales(tester);
    for (var i = 0; i < 20; i++) {
      await tester.tap(_product('tra-da'));
    }
    await tester.pump();
    await _showLines(tester);

    final list = find.byKey(CartPanel.lineListKey);
    expect(find.byType(CartLineTile).evaluate().length, lessThan(20));
    expect(find.text(CartPanel.selectedLabel(20)), findsOneWidget);

    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        )
        .position;
    expect(position.pixels, greaterThan(0));
    expect(position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('f07_note_shown_as_is', (tester) async {
    final note80 = 'ít cơm ' * 11 + 'abc';
    expect(note80.length, kCartLineNoteMaxChars);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CartLineTile(
            line: CartLine(
              productId: 'com-suon',
              name: 'Cơm sườn',
              unitPriceVnd: 45000,
              quantity: 1,
              note: note80,
            ),
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(note80));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(text.style!.fontSize, greaterThanOrEqualTo(16));
  });
}

/// Viết lại công thức bằng tay để test không phụ thuộc vào chính hàm cần thử.
int _vndToBp(int vnd, int subtotal) => vnd * 10000 ~/ subtotal;
