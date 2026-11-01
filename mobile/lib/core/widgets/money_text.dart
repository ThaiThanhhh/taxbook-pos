import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:flutter/material.dart';

/// Hiện số nguyên VND: `1.250.000 ₫`, căn phải, chữ số tabular.
/// Số âm thêm dấu trừ và dùng màu Error (dấu trừ mang thông tin, không chỉ màu).
class MoneyText extends StatelessWidget {
  const MoneyText(this.amount, {this.style, super.key});

  final int amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppTypography.money;
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        MoneyFormat.format(amount),
        textAlign: TextAlign.right,
        style: base.copyWith(
          color: amount < 0 ? AppColors.error : AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
