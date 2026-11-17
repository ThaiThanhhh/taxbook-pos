import 'dart:async';

import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:dt13_pos/features/reports/data/report_providers.dart';
import 'package:dt13_pos/features/reports/domain/report_exporter.dart';
import 'package:dt13_pos/features/reports/domain/report_models.dart';
import 'package:dt13_pos/features/reports/presentation/widgets/report_export_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DailyProfitScreen extends ConsumerStatefulWidget {
  const DailyProfitScreen({super.key});

  @override
  ConsumerState<DailyProfitScreen> createState() => _DailyProfitScreenState();
}

class _DailyProfitScreenState extends ConsumerState<DailyProfitScreen> {
  late final DateTime _date = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final profitAsync = ref.watch(dailyProfitProvider(_date));
    final profit = profitAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lãi/lỗ trong ngày'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Xuất báo cáo',
            onPressed:
                profit != null &&
                    (profit.revenueVnd != 0 || profit.expenseVnd != 0)
                ? () => _showExport(context, profit)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.padding),
          child: profitAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Không thể tải báo cáo: $error',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            data: (data) => _DailyProfitContent(profit: data),
          ),
        ),
      ),
    );
  }

  void _showExport(BuildContext context, DailyProfit profit) {
    unawaited(
      ReportExportSheet.show(
        context,
        title: 'Xuất báo cáo lãi/lỗ',
        textContent: ReportExporter.formatDailyProfitText(profit),
        csvContent: ReportExporter.formatDailyProfitCsv(profit),
      ),
    );
  }
}

class _DailyProfitContent extends StatelessWidget {
  const _DailyProfitContent({required this.profit});

  final DailyProfit profit;

  @override
  Widget build(BuildContext context) {
    if (profit.revenueVnd == 0 && profit.expenseVnd == 0) {
      return const Center(child: Text('Chưa có giao dịch trong ngày này.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DateFormat('dd/MM/yyyy').format(profit.date),
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.padding),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfitRow(label: 'Tổng doanh thu', amount: profit.revenueVnd),
              const SizedBox(height: 12),
              _ProfitRow(label: 'Tổng chi phí', amount: profit.expenseVnd),
              const Divider(height: 24),
              _ProfitRow(
                label: profit.profitVnd < 0
                    ? 'Lỗ trong ngày'
                    : 'Lãi trong ngày',
                amount: profit.profitVnd,
                emphasize: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final int amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? AppTypography.titleSmall
                : AppTypography.bodyLarge,
          ),
        ),
        Text(
          MoneyFormat.format(amount),
          style: (emphasize ? AppTypography.titleSmall : AppTypography.money)
              .copyWith(color: amount < 0 ? AppColors.error : null),
        ),
      ],
    );
  }
}
