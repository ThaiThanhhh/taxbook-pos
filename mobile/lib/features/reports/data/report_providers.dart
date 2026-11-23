import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/features/reports/data/report_repository.dart';
import 'package:dt13_pos/features/reports/domain/report_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ApiReportRepository(ref.watch(apiClientProvider));
});

final dailyProfitProvider = FutureProvider.family<DailyProfit, DateTime>((
  ref,
  date,
) {
  return ref.watch(reportRepositoryProvider).fetchDailyProfit(date);
});

final topProductsProvider =
    FutureProvider.family<List<TopProduct>, ({DateTime from, DateTime to})>((
      ref,
      period,
    ) {
      return ref
          .watch(reportRepositoryProvider)
          .fetchTopProducts(from: period.from, to: period.to);
    });
