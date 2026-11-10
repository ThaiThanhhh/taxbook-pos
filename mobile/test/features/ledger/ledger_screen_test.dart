import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:dt13_pos/features/ledger/presentation/ledger_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testDate = DateTime(2026, 11, 5);

  Widget createWidgetUnderTest(dynamic overrideItem) {
    return ProviderScope(
      retry: (count, error) => null,
      overrides: [overrideItem].cast(),
      child: MaterialApp(home: LedgerScreen(initialDate: testDate)),
    );
  }

  testWidgets('Hiển thị danh sách ghi chép sổ doanh thu', (tester) async {
    const page = LedgerPage(
      items: [
        LedgerEntry(
          id: '1',
          book: 'REVENUE',
          entryDate: '2026-11-05',
          type: 'REVENUE',
          amountVnd: 90000,
          refType: 'SALE',
          refId: 'sale-1',
          category: 'SERVICE',
        ),
      ],
      hasMore: false,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        ledgerPageProvider(
          from: testDate,
          to: testDate,
          book: 'REVENUE',
        ).overrideWith((ref) async => page),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sổ thu chi'), findsOneWidget);
    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.text('90.000 ₫'), findsOneWidget);
  });

  testWidgets('Hiển thị nhãn Hủy đơn khi refType là SALE_REVERSAL', (
    tester,
  ) async {
    const page = LedgerPage(
      items: [
        LedgerEntry(
          id: '2',
          book: 'REVENUE',
          entryDate: '2026-11-05',
          type: 'REVENUE',
          amountVnd: -90000,
          refType: 'SALE_REVERSAL',
          refId: 'sale-1',
          note: 'Khách đổi ý',
        ),
      ],
      hasMore: false,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        ledgerPageProvider(
          from: testDate,
          to: testDate,
          book: 'REVENUE',
        ).overrideWith((ref) async => page),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hủy đơn'), findsNWidgets(2));
    expect(find.text('-90.000 ₫'), findsOneWidget);
  });

  testWidgets('Hiển thị EmptyState khi sổ rỗng', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        ledgerPageProvider(
          from: testDate,
          to: testDate,
          book: 'REVENUE',
        ).overrideWith(
          (ref) async => const LedgerPage(items: [], hasMore: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('Hiển thị thông báo lỗi khi có exception', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        ledgerPageProvider(
          from: testDate,
          to: testDate,
          book: 'REVENUE',
        ).overrideWith(
          (ref) => Future<LedgerPage>.error(
            const LedgerException(
              'Cần kết nối mạng để xem sổ thu chi.',
              kind: LedgerErrorKind.offline,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Cần kết nối mạng để xem sổ thu chi.'), findsOneWidget);
  });
}
