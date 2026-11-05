import 'dart:async';

import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/features/reports/data/reports_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DailyProfitScreen extends ConsumerStatefulWidget {
  const DailyProfitScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<DailyProfitScreen> createState() => _DailyProfitScreenState();
}

class _DailyProfitScreenState extends ConsumerState<DailyProfitScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(base.year, base.month, base.day);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    if (day != _selectedDate) {
      setState(() => _selectedDate = day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profitAsync = ref.watch(dailyProfitProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo ngày'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Chọn ngày',
            onPressed: () => unawaited(_selectDate()),
          ),
        ],
      ),
      body: profitAsync.when(
        data: (profit) {
          if (profit.revenueVnd == 0 && profit.expenseVnd == 0) {
            return const EmptyState(
              title: 'Chưa có giao dịch',
              message: 'Doanh thu và chi phí trong ngày sẽ hiện ở đây.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.padding),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.padding),
                child: Text(
                  'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  style: AppTypography.titleSmall,
                ),
              ),
              _AmountRow(label: 'Tổng doanh thu', amount: profit.revenueVnd),
              const SizedBox(height: AppSpacing.padding),
              _AmountRow(label: 'Tổng chi phí', amount: profit.expenseVnd),
              const SizedBox(height: AppSpacing.padding),
              _AmountRow(
                label: profit.isLoss ? 'Lỗ trong ngày' : 'Lãi trong ngày',
                amount: profit.profitVnd,
                emphasized: true,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: 'Không tải được báo cáo. Vui lòng thử lại.',
          onRetry: () => ref.invalidate(dailyProfitProvider(_selectedDate)),
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final int amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized
                  ? AppTypography.titleSmall
                  : AppTypography.bodyLarge,
            ),
          ),
          MoneyText(amount),
        ],
      ),
    );
  }
}
