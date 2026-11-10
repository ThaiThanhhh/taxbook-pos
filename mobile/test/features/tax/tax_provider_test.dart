import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:dt13_pos/features/tax/domain/tax_engine.dart';
import 'package:dt13_pos/features/tax/presentation/providers/tax_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaxEngine', () {
    const engine = TaxEngine();

    test('waives all taxes at the one-billion threshold', () {
      final result = engine.calculateTax(
        sector: TaxSector.SERVICE,
        annualRevenue: TaxEngine.NGUONG_1_TY,
        totalExpense: 0,
      );

      expect(result.gtgt, 0);
      expect(result.tncnCach1, 0);
      expect(result.tncnLoiNhuan, 0);
    });

    test('calculates sector rates and profit tax thresholds', () {
      final result = engine.calculateTax(
        sector: TaxSector.GOODS_DISTRIBUTION,
        annualRevenue: 4000000000,
        totalExpense: 1000000000,
      );

      expect(result.gtgt, 40000000);
      expect(result.tncnCach1, isNull);
      expect(result.tncnLoiNhuan, 510000000);
    });

    test('uses the correct revenue rate for each sector', () {
      const sectors = {
        TaxSector.GOODS_DISTRIBUTION: (20000000, 0.5),
        TaxSector.SERVICE: (100000000, 2.0),
        TaxSector.PRODUCTION_TRANSPORT: (60000000, 1.5),
        TaxSector.OTHER: (40000000, 1.0),
      };

      for (final entry in sectors.entries) {
        final result = engine.calculateTax(
          sector: entry.key,
          annualRevenue: 2000000000,
          totalExpense: 0,
        );

        expect(result.gtgt, entry.value.$1);
        expect(result.tncnCach1, 1000000000 * entry.value.$2 ~/ 100);
      }
    });
  });

  test(
    'taxProvider aggregates annual revenue and expenses from the ledger',
    () async {
      final year = DateTime.now().year;
      final from = DateTime(year, 1, 1);
      final to = DateTime(year, 12, 31);
      const revenuePage = LedgerPage(
        items: [
          LedgerEntry(
            id: 'revenue',
            book: 'REVENUE',
            entryDate: '2026-01-01',
            type: 'REVENUE',
            amountVnd: 2000000000,
            category: 'SERVICE',
          ),
          LedgerEntry(
            id: 'reversal',
            book: 'REVENUE',
            entryDate: '2026-01-02',
            type: 'REVENUE',
            amountVnd: -100000000,
            refType: 'SALE_REVERSAL',
            category: 'SERVICE',
          ),
        ],
        hasMore: false,
      );
      const expensePage = LedgerPage(
        items: [
          LedgerEntry(
            id: 'expense',
            book: 'EXPENSE',
            entryDate: '2026-01-03',
            type: 'EXPENSE',
            amountVnd: 500000000,
            category: 'SERVICE',
          ),
        ],
        hasMore: false,
      );
      final container = ProviderContainer(
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
      );
      addTearDown(container.dispose);

      final result = await container.read(
        taxProvider((sector: TaxSector.SERVICE, from: from, to: to)).future,
      );

      expect(result.annualRevenue, 1900000000);
      expect(result.totalExpense, 500000000);
      expect(result.gtgt, 95000000);
      expect(result.tncnCach1, 18000000);
      expect(result.tncnLoiNhuan, 210000000);
    },
  );

  test(
    'taxProvider refuses to calculate from incomplete ledger pages',
    () async {
      final year = DateTime.now().year;
      final from = DateTime(year, 1, 1);
      final to = DateTime(year, 12, 31);
      const page = LedgerPage(items: [], hasMore: true);
      final container = ProviderContainer(
        overrides: [
          ledgerPageProvider(
            from: from,
            to: to,
            book: 'REVENUE',
          ).overrideWith((ref) async => page),
          ledgerPageProvider(
            from: from,
            to: to,
            book: 'EXPENSE',
          ).overrideWith((ref) async => page),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(
          taxProvider((sector: TaxSector.SERVICE, from: from, to: to)).future,
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
