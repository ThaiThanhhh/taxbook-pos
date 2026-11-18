import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/features/sales/domain/cart_calc.dart';
import 'package:flutter/material.dart';

/// Một dòng trong giỏ (F07): tên món, ghi chú, nút bớt/thêm và thành tiền.
///
/// - Hai nút bớt/thêm vuông, cạnh tối thiểu [AppSpacing.minTapTarget] (48).
/// - Thành tiền lấy từ [lineNetVnd] (cùng công thức với calcCart), căn phải.
/// - Ghi chú hiện nguyên văn: notifier đã cắt ở 80 ký tự, widget không cắt
///   thêm và không đặt giới hạn riêng.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  static const String incrementTooltip = 'Thêm một';
  static const String decrementTooltip = 'Bớt một';

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.padding,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(line.name, style: AppTypography.bodyLarge),
                if (line.note.isNotEmpty)
                  Text(
                    line.note,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StepButton(
            icon: Icons.remove,
            tooltip: decrementTooltip,
            onPressed: onDecrement,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Text(
              '${line.quantity}',
              textAlign: TextAlign.center,
              style: AppTypography.money,
              semanticsLabel: 'Số lượng ${line.quantity}',
            ),
          ),
          _StepButton(
            icon: Icons.add,
            tooltip: incrementTooltip,
            onPressed: onIncrement,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            // Màn hẹp + chữ hệ thống lớn: số tiền co lại, không xuống dòng.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: MoneyText(lineNetVnd(line)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      icon: Icon(icon, size: AppSpacing.icon),
      onPressed: onPressed,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTapTarget,
        minHeight: AppSpacing.minTapTarget,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        side: const BorderSide(color: AppColors.inputBorder),
      ),
    );
  }
}
