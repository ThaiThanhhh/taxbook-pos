import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/tax/domain/tax_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taxProvider =
    FutureProvider.family<
      TaxCalculation,
      ({TaxSector sector, DateTime from, DateTime to})
    >((ref, query) async {
      final revenuePageFuture = ref.watch(
        ledgerPageProvider(
          from: query.from,
          to: query.to,
          book: 'REVENUE',
        ).future,
      );
      final expensePageFuture = ref.watch(
        ledgerPageProvider(
          from: query.from,
          to: query.to,
          book: 'EXPENSE',
        ).future,
      );
      final pages = await Future.wait([revenuePageFuture, expensePageFuture]);
      final revenuePage = pages[0];
      final expensePage = pages[1];

      if (revenuePage.hasMore || expensePage.hasMore) {
        throw StateError(
          'Chưa thể tính thuế vì dữ liệu sổ doanh thu hoặc chi phí còn trang chưa tải.',
        );
      }

      final annualRevenue = revenuePage.items
          .where((entry) => _sectorForCategory(entry.category) == query.sector)
          .fold<int>(0, (total, entry) => total + entry.signedAmount);
      final totalExpense = expensePage.items
          .where((entry) => _sectorForCategory(entry.category) == query.sector)
          .fold<int>(0, (total, entry) => total + entry.amountVnd.abs());

      return const TaxEngine().calculateTax(
        sector: query.sector,
        annualRevenue: annualRevenue,
        totalExpense: totalExpense,
      );
    });

TaxSector _sectorForCategory(String? category) => switch (category) {
  'GOODS_DISTRIBUTION' => TaxSector.GOODS_DISTRIBUTION,
  'SERVICE' => TaxSector.SERVICE,
  'PRODUCTION_TRANSPORT' => TaxSector.PRODUCTION_TRANSPORT,
  _ => TaxSector.OTHER,
};
