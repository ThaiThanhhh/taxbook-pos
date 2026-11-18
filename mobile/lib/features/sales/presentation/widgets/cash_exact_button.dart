import 'package:dt13_pos/core/db/db_values.dart';
import 'package:dt13_pos/core/utils/app_logger.dart';
import 'package:dt13_pos/core/widgets/app_button.dart';
import 'package:dt13_pos/core/widgets/secondary_button.dart';
import 'package:dt13_pos/features/sales/data/save_order_provider.dart';
import 'package:dt13_pos/features/sales/presentation/cart_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nút tạm của F08: khách đưa đúng tổng tiền mặt -> lưu đơn rồi xóa giỏ.
///
/// Đang lưu thì nút hiện vòng tròn và chặn bấm; SaveOrder cũng tự chặn gọi
/// chồng, nên bấm đôi không mở transaction thứ hai.
class CashExactButton extends ConsumerStatefulWidget {
  const CashExactButton({super.key});

  static const String label = 'Thu đủ tiền mặt';
  static const String failedMessage = 'Chưa lưu được đơn. Bấm lại để thử.';

  static String savedMessage(String tempNumber) => 'Đã lưu đơn $tempNumber';

  @override
  ConsumerState<CashExactButton> createState() => _CashExactButtonState();
}

class _CashExactButtonState extends ConsumerState<CashExactButton> {
  bool _saving = false;

  Future<void> _save() async {
    final cart = ref.read(cartProvider);
    if (_saving || cart.isEmpty || cart.orderDiscountRejected) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final saved = await ref
          .read(saveOrderProvider)
          .call(
            cart.lines,
            orderDiscountBp: cart.orderDiscountBp,
            paymentMethod: PaymentMethod.cash,
          );
      if (mounted) ref.read(cartProvider.notifier).clear();
      message = CashExactButton.savedMessage(saved.tempNumber);
    } catch (error, stackTrace) {
      // Không log giỏ hay payload: chỉ loại lỗi, ở bản debug.
      AppLogger.e('Không lưu được đơn', error: error, stackTrace: stackTrace);
      message = CashExactButton.failedMessage;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final enabled = !cart.isEmpty && !cart.orderDiscountRejected;
    return SecondaryButton(
      label: CashExactButton.label,
      size: AppButtonSize.large,
      expanded: true,
      isLoading: _saving,
      onPressed: enabled ? _save : null,
    );
  }
}
