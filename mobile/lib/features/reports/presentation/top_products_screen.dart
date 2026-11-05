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

class TopProductsScreen extends ConsumerStatefulWidget {
  const TopProductsScreen({super.key, this.initialRange});

  final DateTimeRange? initialRange;

  @override
  ConsumerState<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends ConsumerState<TopProductsScreen> {
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRange;
    if (initial != null) {
      _range = _dateOnly(initial);
    } else {
      final now = DateTime.now();
      _range = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      );
    }
  }

  static DateTimeRange _dateOnly(DateTimeRange r) => DateTimeRange(
    start: DateTime(r.start.year, r.start.month, r.start.day),
    end: DateTime(r.end.year, r.end.month, r.end.day),
  );

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() => _range = _dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final productsAsync = ref.watch(
      topProductsProvider(from: _range.start, to: _range.end),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm bán chạy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Chọn khoảng ngày',
            onPressed: () => unawaited(_pickRange()),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.padding),
            child: Text(
              'Từ ${dateFormat.format(_range.start)} '
              'đến ${dateFormat.format(_range.end)}',
              style: AppTypography.titleSmall,
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyState(
                    title: 'Chưa có dữ liệu',
                    message: 'Chưa có sản phẩm nào được bán trong khoảng này.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.padding,
                    0,
                    AppSpacing.padding,
                    AppSpacing.padding,
                  ),
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.padding),
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Text(
                              '${index + 1}',
                              style: AppTypography.titleSmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.padding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTypography.titleSmall,
                                ),
                                Text(
                                  'Đã bán: ${item.qty}',
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          MoneyText(item.revenueVnd),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: 'Không thể tải danh sách sản phẩm.',
                onRetry: () => ref.invalidate(
                  topProductsProvider(from: _range.start, to: _range.end),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
