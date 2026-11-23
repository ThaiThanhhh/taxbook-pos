import 'dart:async';

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

class TopProductsScreen extends ConsumerStatefulWidget {
  const TopProductsScreen({super.key});

  @override
  ConsumerState<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends ConsumerState<TopProductsScreen> {
  late final DateTime _to = DateUtils.dateOnly(DateTime.now());
  late final DateTime _from = _to.subtract(const Duration(days: 29));

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      topProductsProvider((from: _from, to: _to)),
    );
    final products = productsAsync.value ?? const <TopProduct>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm bán chạy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Xuất báo cáo',
            onPressed: products.isNotEmpty
                ? () => _showExport(context, products)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.padding),
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Không thể tải báo cáo: $error',
                style: AppTypography.bodyMedium,
              ),
            ),
            data: (items) => items.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có sản phẩm bán trong khoảng thời gian này.',
                    ),
                  )
                : _TopProductsContent(products: items, from: _from, to: _to),
          ),
        ),
      ),
    );
  }

  void _showExport(BuildContext context, List<TopProduct> products) {
    unawaited(
      ReportExportSheet.show(
        context,
        title: 'Xuất báo cáo sản phẩm bán chạy',
        textContent: ReportExporter.formatTopProductsText(
          products,
          from: _from,
          to: _to,
        ),
        csvContent: ReportExporter.formatTopProductsCsv(products),
      ),
    );
  }
}

class _TopProductsContent extends StatelessWidget {
  const _TopProductsContent({
    required this.products,
    required this.from,
    required this.to,
  });

  final List<TopProduct> products;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final range = DateFormat('dd/MM/yyyy');
    return ListView(
      children: [
        Text(
          'Thời gian: ${range.format(from)} - ${range.format(to)}',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.padding),
        for (var index = 0; index < products.length; index++) ...[
          AppCard(
            child: Row(
              children: [
                CircleAvatar(child: Text('${index + 1}')),
                const SizedBox(width: AppSpacing.padding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        products[index].name,
                        style: AppTypography.titleSmall,
                      ),
                      Text(
                        'Đã bán: ${products[index].qty}',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  MoneyFormat.format(products[index].revenueVnd),
                  style: AppTypography.money,
                ),
              ],
            ),
          ),
          if (index < products.length - 1)
            const SizedBox(height: AppSpacing.padding),
        ],
      ],
    );
  }
}
