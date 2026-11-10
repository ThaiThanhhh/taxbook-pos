import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:dt13_pos/features/tax/domain/tax_engine.dart';
import 'package:dt13_pos/features/tax/presentation/providers/tax_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _TaxPeriod {
  quarter1('Quý 1', 1, 3),
  quarter2('Quý 2', 4, 6),
  quarter3('Quý 3', 7, 9),
  quarter4('Quý 4', 10, 12),
  year('Cả năm 2026', 1, 12);

  const _TaxPeriod(this.label, this.startMonth, this.endMonth);

  final String label;
  final int startMonth;
  final int endMonth;

  DateTime get from => DateTime(2026, startMonth, 1);
  DateTime get to => DateTime(2026, endMonth + 1, 0);
}

class TaxScreen extends ConsumerStatefulWidget {
  const TaxScreen({super.key});

  @override
  ConsumerState<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends ConsumerState<TaxScreen> {
  _TaxPeriod _selectedPeriod = _TaxPeriod.year;

  @override
  Widget build(BuildContext context) {
    final calculations = {
      for (final sector in TaxSector.values)
        sector: ref.watch(
          taxProvider((
            sector: sector,
            from: _selectedPeriod.from,
            to: _selectedPeriod.to,
          )),
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Thuế tạm tính')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.padding,
                AppSpacing.padding,
                0,
                AppSpacing.padding,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_TaxPeriod>(
                  segments: [
                    for (final period in _TaxPeriod.values)
                      ButtonSegment(value: period, label: Text(period.label)),
                  ],
                  selected: {_selectedPeriod},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _selectedPeriod = selection.first);
                  },
                ),
              ),
            ),
            Expanded(child: _buildPeriodContent(calculations)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodContent(
    Map<TaxSector, AsyncValue<TaxCalculation>> calculations,
  ) {
    if (calculations.values.any((value) => value.hasError)) {
      final error = calculations.values.firstWhere((value) => value.hasError);
      return ErrorState(
        message: error.error.toString(),
        onRetry: () {
          for (final sector in TaxSector.values) {
            ref.invalidate(
              taxProvider((
                sector: sector,
                from: _selectedPeriod.from,
                to: _selectedPeriod.to,
              )),
            );
          }
        },
      );
    }

    if (calculations.values.any((value) => value.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = {
      for (final entry in calculations.entries)
        entry.key: entry.value.requireValue,
    };
    if (data.values.every(
      (calculation) =>
          calculation.annualRevenue == 0 && calculation.totalExpense == 0,
    )) {
      return const EmptyState(
        title: 'Chưa có dữ liệu thuế',
        message: 'Chưa có doanh thu hoặc chi phí trong kỳ đã chọn.',
      );
    }

    final revenueRatioTax = _sumOptional(
      data.values.map((calculation) => calculation.tncnCach1),
    );
    final totalGtgt = data.values.fold<int>(
      0,
      (total, calculation) => total + calculation.gtgt,
    );
    final totalProfitTax = data.values.fold<int>(
      0,
      (total, calculation) => total + calculation.tncnLoiNhuan,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.padding,
        0,
        AppSpacing.padding,
        AppSpacing.padding,
      ),
      children: [
        const _UnverifiedNotice(),
        const SizedBox(height: AppSpacing.padding),
        _OverviewCard(
          gtgt: totalGtgt,
          tncnCach1: revenueRatioTax,
          tncnLoiNhuan: totalProfitTax,
        ),
        const SizedBox(height: AppSpacing.padding),
        const Text('Chi tiết theo ngành nghề', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.padding),
        for (final sector in TaxSector.values) ...[
          _SectorCard(sector: sector, calculation: data[sector]!),
          const SizedBox(height: AppSpacing.padding),
        ],
        Text(
          'Số liệu ước tính dựa trên dữ liệu sổ thu chi đã ghi nhận.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

int? _sumOptional(Iterable<int?> values) {
  var total = 0;
  for (final value in values) {
    if (value == null) return null;
    total += value;
  }
  return total;
}

String _sectorLabel(TaxSector sector) => switch (sector) {
  TaxSector.GOODS_DISTRIBUTION => 'Phân phối hàng hóa',
  TaxSector.SERVICE => 'Dịch vụ',
  TaxSector.PRODUCTION_TRANSPORT => 'Sản xuất / Vận tải',
  TaxSector.OTHER => 'Khác',
};

class _UnverifiedNotice extends StatelessWidget {
  const _UnverifiedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.padding),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tham số thuế đang ở trạng thái dự thảo, cần xác minh trước khi sử dụng kê khai.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.gtgt,
    required this.tncnCach1,
    required this.tncnLoiNhuan,
  });

  final int gtgt;
  final int? tncnCach1;
  final int tncnLoiNhuan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng số thuế tạm tính', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.padding),
          _TaxMethodTotal(
            title: 'Thuế tính theo tỷ lệ phần vượt',
            gtgt: gtgt,
            tncn: tncnCach1,
          ),
          const Divider(height: 24),
          _TaxMethodTotal(
            title: 'Thuế tính theo lợi nhuận',
            gtgt: gtgt,
            tncn: tncnLoiNhuan,
          ),
        ],
      ),
    );
  }
}

class _TaxMethodTotal extends StatelessWidget {
  const _TaxMethodTotal({
    required this.title,
    required this.gtgt,
    required this.tncn,
  });

  final String title;
  final int gtgt;
  final int? tncn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodyMedium),
        const SizedBox(height: 8),
        _DetailLine(label: 'Thuế GTGT', amount: gtgt),
        const SizedBox(height: 4),
        _DetailLine(label: 'Thuế TNCN', amount: tncn),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tổng cộng',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            Text(
              tncn == null ? 'Không áp dụng' : MoneyFormat.format(gtgt + tncn!),
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({required this.sector, required this.calculation});

  final TaxSector sector;
  final TaxCalculation calculation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_sectorLabel(sector), style: AppTypography.titleSmall),
          const SizedBox(height: 12),
          _DetailLine(label: 'Doanh thu', amount: calculation.annualRevenue),
          _DetailLine(label: 'Chi phí', amount: calculation.totalExpense),
          const Divider(height: 24),
          _DetailLine(label: 'Thuế GTGT', amount: calculation.gtgt),
          _DetailLine(
            label: 'TNCN theo tỷ lệ phần vượt',
            amount: calculation.tncnCach1,
          ),
          _DetailLine(
            label: 'TNCN theo lợi nhuận',
            amount: calculation.tncnLoiNhuan,
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.amount});

  final String label;
  final int? amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            amount == null ? 'Không áp dụng' : MoneyFormat.format(amount!),
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
