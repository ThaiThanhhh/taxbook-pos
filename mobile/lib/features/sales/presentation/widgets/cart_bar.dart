import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_button.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:dt13_pos/features/sales/presentation/cart_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thanh đáy màn bán: số món, tổng tiền và nút Thu tiền (cao 52).
///
/// Tổng lấy từ `CartState.totals` (do calcCart tính), không tự nhân giá.
/// Giỏ rỗng thì nút Thu tiền tắt.
class CartBar extends ConsumerWidget {
  const CartBar({super.key});

  static const String notSavedMessage = 'Chưa lưu được';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final itemCount = cart.lines.fold<int>(
      0,
      (sum, line) => sum + line.quantity,
    );

    return Material(
      color: AppColors.surface,
      shape: const Border(top: BorderSide(color: AppColors.border)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('$itemCount món', style: AppTypography.bodyLarge),
                  const SizedBox(width: AppSpacing.padding),
                  Expanded(
                    child: MoneyText(
                      cart.totals.totalVnd,
                      style: AppTypography.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Thu tiền',
                size: AppButtonSize.large,
                onPressed: cart.isEmpty
                    ? null
                    // TODO(Mobile Dev 1, US-305): lưu đơn (SaveOrder) rồi mở
                    // /payment, thay cho SnackBar tạm này.
                    : () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text(notSavedMessage)),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
