import 'dart:async';

import 'package:dt13_pos/core/ports/clock.dart';
import 'package:dt13_pos/core/ports/order_write_dao.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/core/utils/uuid_v7_id_generator.dart';
import 'package:dt13_pos/features/sales/data/product_catalog_provider.dart';
import 'package:dt13_pos/features/sales/data/save_order_provider.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:dt13_pos/features/sales/domain/save_order.dart';
import 'package:dt13_pos/features/sales/presentation/cart_notifier.dart';
import 'package:dt13_pos/features/sales/presentation/sales_screen.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cash_exact_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixture = <Product>[
  Product(
    id: 'com-suon',
    name: 'Cơm sườn',
    unitPriceVnd: 45000,
    unitLabel: 'phần',
  ),
];

final class _FakeCatalog implements ProductCatalog {
  @override
  Future<List<Product>> listForSale() async => _fixture;
}

final class _FixedClock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 11, 13, 3);
}

/// DAO giả không mở SQLite (test widget chạy trong fake-async).
final class _FakeDao implements OrderWriteDao {
  int transactions = 0;
  int orders = 0;
  int seq = 0;
  Completer<void>? gate;
  bool failOnOrder = false;

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    transactions++;
    final pending = gate;
    if (pending != null) await pending.future;
    return action();
  }

  @override
  Future<int> nextDaySeq({
    required String devicePrefix,
    required String dayKey,
  }) async => ++seq;

  @override
  Future<void> insertOrder(NewOrder order) async {
    if (failOnOrder) throw StateError('disk full');
    orders++;
  }

  @override
  Future<void> insertOrderItem(NewOrderItem item) async {}

  @override
  Future<void> insertOutbox(NewOutboxEntry entry) async {}
}

Future<ProviderContainer> _pump(WidgetTester tester, _FakeDao dao) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final clock = _FixedClock();
  final container = ProviderContainer(
    overrides: [
      productCatalogProvider.overrideWithValue(_FakeCatalog()),
      saveOrderProvider.overrideWithValue(
        SaveOrder(
          dao: dao,
          clock: clock,
          ids: UuidV7IdGenerator(clock),
          devicePrefix: 'A1',
        ),
      ),
    ],
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

Finder get _cashButton =>
    find.widgetWithText(FilledButton, CashExactButton.label);

void main() {
  testWidgets('f08_button_saves_and_clears_cart', (tester) async {
    final dao = _FakeDao();
    final container = await _pump(tester, dao);

    expect(tester.widget<FilledButton>(_cashButton).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('com-suon')));
    await tester.pump();
    expect(tester.widget<FilledButton>(_cashButton).onPressed, isNotNull);
    expect(tester.getSize(_cashButton).height, AppSpacing.buttonHeightLarge);

    await tester.tap(_cashButton);
    await tester.pumpAndSettle();

    expect(dao.transactions, 1);
    expect(dao.orders, 1);
    expect(container.read(cartProvider).isEmpty, isTrue);
    expect(find.text('Đã lưu đơn A1-261113-0001'), findsOneWidget);
    expect(tester.widget<FilledButton>(_cashButton).onPressed, isNull);
  });

  testWidgets('f08_button_double_tap_one_transaction', (tester) async {
    final dao = _FakeDao()..gate = Completer<void>();
    final container = await _pump(tester, dao);
    await tester.tap(find.byKey(const ValueKey('com-suon')));
    await tester.pump();

    await tester.tap(_cashButton);
    await tester.pump();
    // Đang lưu: nút hiện vòng tròn và không nhận bấm.
    expect(
      find.descendant(
        of: _cashButton,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await tester.tap(_cashButton, warnIfMissed: false);
    await tester.pump();
    expect(dao.transactions, 1);

    dao.gate!.complete();
    await tester.pumpAndSettle();

    expect(dao.transactions, 1);
    expect(dao.orders, 1);
    expect(container.read(cartProvider).isEmpty, isTrue);
  });

  testWidgets('f08_button_failure_keeps_cart_and_allows_retry', (tester) async {
    final dao = _FakeDao()..failOnOrder = true;
    final container = await _pump(tester, dao);
    await tester.tap(find.byKey(const ValueKey('com-suon')));
    await tester.pump();

    await tester.tap(_cashButton);
    await tester.pumpAndSettle();

    expect(find.text(CashExactButton.failedMessage), findsOneWidget);
    expect(container.read(cartProvider).lines, hasLength(1));
    expect(tester.widget<FilledButton>(_cashButton).onPressed, isNotNull);

    dao.failOnOrder = false;
    await tester.tap(_cashButton);
    await tester.pumpAndSettle();

    expect(container.read(cartProvider).isEmpty, isTrue);
    expect(dao.orders, 1);
  });
}
