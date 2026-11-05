import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/features/reports/data/reports_repository.dart';
import 'package:dt13_pos/features/reports/domain/daily_profit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_providers.g.dart';

@riverpod
ReportsRepository reportsRepository(Ref ref) =>
    ReportsRepository(ref.watch(apiClientProvider));

/// [date] được chuẩn hóa về ngày thuần để cùng một ngày luôn gọi API một lần.
@riverpod
Future<DailyProfit> dailyProfit(Ref ref, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return ref.watch(reportsRepositoryProvider).getDailyProfit(day);
}
