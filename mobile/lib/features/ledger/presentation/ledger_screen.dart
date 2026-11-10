import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum LedgerBookFilter {
  revenue('REVENUE', 'Sổ doanh thu'),
  expense('EXPENSE', 'Sổ chi phí'),
  cash('CASH', 'Sổ tiền mặt'),
  bank('BANK', 'Sổ ngân hàng'),
  all(null, 'Tất cả sổ');

  const LedgerBookFilter(this.code, this.label);
  final String? code;
  final String label;
}

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  late DateTime _selectedDate;
  LedgerBookFilter _selectedFilter = LedgerBookFilter.revenue;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(base.year, base.month, base.day);
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(
      ledgerPageProvider(
        from: _selectedDate,
        to: _selectedDate,
        book: _selectedFilter.code,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ thu chi'),
        actions: [
          PopupMenuButton<LedgerBookFilter>(
            initialValue: _selectedFilter,
            onSelected: (val) => setState(() => _selectedFilter = val),
            itemBuilder: (context) => LedgerBookFilter.values
                .map((f) => PopupMenuItem(value: f, child: Text(f.label)))
                .toList(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.padding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  style: AppTypography.titleSmall,
                ),
                Text(_selectedFilter.label, style: AppTypography.bodyMedium),
              ],
            ),
          ),
          Expanded(
            child: pageAsync.when(
              data: (page) {
                final entries = page.items;
                if (entries.isEmpty) {
                  return const EmptyState(
                    title: 'Chưa có ghi chép',
                    message: 'Không có giao dịch nào trong ngày này.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.padding,
                    0,
                    AppSpacing.padding,
                    AppSpacing.padding,
                  ),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.padding),
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return _LedgerItemCard(item: item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(
                  ledgerPageProvider(
                    from: _selectedDate,
                    to: _selectedDate,
                    book: _selectedFilter.code,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerItemCard extends StatelessWidget {
  const _LedgerItemCard({required this.item});

  final LedgerEntry item;

  @override
  Widget build(BuildContext context) {
    final color = item.isNegative ? AppColors.error : AppColors.success;

    return AppCard(
      child: Row(
        children: [
          Icon(
            item.isNegative ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
          const SizedBox(width: AppSpacing.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.title, style: AppTypography.titleSmall),
                    if (item.isReversal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Hủy đơn',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(item.subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          MoneyText(item.signedAmount),
        ],
      ),
    );
  }
}
