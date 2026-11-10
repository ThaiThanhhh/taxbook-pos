import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:dt13_pos/features/tax/presentation/tax_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows selected tax period and breakdown by sector', (
    tester,
  ) async {
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 12, 31);
    const revenuePage = LedgerPage(
      items: [
        LedgerEntry(
          id: 'service-revenue',
          book: 'REVENUE',
          entryDate: '2026-01-01',
          type: 'REVENUE',
          amountVnd: 2000000000,
          category: 'SERVICE',
        ),
      ],
      hasMore: false,
    );
    const expensePage = LedgerPage(
      items: [
        LedgerEntry(
          id: 'service-expense',
          book: 'EXPENSE',
          entryDate: '2026-01-02',
          type: 'EXPENSE',
          amountVnd: 500000000,
          category: 'SERVICE',
        ),
      ],
      hasMore: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerPageProvider(
            from: from,
            to: to,
            book: 'REVENUE',
          ).overrideWith((ref) async => revenuePage),
          ledgerPageProvider(
            from: from,
            to: to,
            book: 'EXPENSE',
          ).overrideWith((ref) async => expensePage),
        ],
        child: const MaterialApp(home: TaxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cả năm 2026'), findsOneWidget);
    expect(find.text('Quý 1'), findsOneWidget);
    expect(find.textContaining('trạng thái dự thảo'), findsOneWidget);
    expect(find.text('Tổng số thuế tạm tính'), findsOneWidget);
    expect(find.text('Thuế tính theo tỷ lệ phần vượt'), findsOneWidget);
    expect(find.text('Thuế tính theo lợi nhuận'), findsOneWidget);
    expect(find.text('Chi tiết theo ngành nghề'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Dịch vụ'), findsOneWidget);
    expect(find.text('2.000.000.000 ₫'), findsOneWidget);
    expect(find.text('500.000.000 ₫'), findsOneWidget);
  });

  testWidgets('shows an empty state when the ledger has no data', (
    tester,
  ) async {
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 12, 31);
    const emptyPage = LedgerPage(items: [], hasMore: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerPageProvider(
            from: from,
            to: to,
            book: 'REVENUE',
          ).overrideWith((ref) async => emptyPage),
          ledgerPageProvider(
            from: from,
            to: to,
            book: 'EXPENSE',
          ).overrideWith((ref) async => emptyPage),
        ],
        child: const MaterialApp(home: TaxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có dữ liệu thuế'), findsOneWidget);
  });
}
