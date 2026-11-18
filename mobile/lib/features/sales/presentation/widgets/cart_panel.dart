import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_text_field.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/features/sales/domain/discount_bp.dart';
import 'package:dt13_pos/features/sales/presentation/cart_notifier.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cart_line_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Khung giỏ trên màn bán (F07): danh sách dòng và ô giảm cả đơn.
///
/// Mặc định thu gọn để chừa vùng lướt món đang bán. Khi mở, từng dòng và phần
/// giảm giá cuối giỏ cùng cuộn trong khung giới hạn bởi SalesScreen. Tổng tiền
/// và nút Thu tiền luôn hiện riêng ở CartBar. Thu gọn không xóa số giảm.
class CartPanel extends ConsumerStatefulWidget {
  const CartPanel({super.key});

  static const String discountLabel = 'Giảm cả đơn';
  static const String subtotalLabel = 'Tạm tính';
  static const String appliedLabel = 'Được giảm';
  static const String overSubtotalError = 'Số giảm lớn hơn tạm tính';
  static const String collapseTooltip = 'Thu gọn';
  static const String expandTooltip = 'Xem món đã chọn';

  static String selectedLabel(int count) => 'Đã chọn $count món';

  static const Key discountFieldKey = ValueKey('cart-discount-field');
  static const Key lineListKey = ValueKey('cart-line-list');

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  final TextEditingController _discountController = TextEditingController();
  int? _discountVnd;
  String? _discountError;
  bool _expanded = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _onDiscountChanged(int? vnd) {
    _discountVnd = vnd;
    _applyDiscount(_baseVnd(ref.read(cartProvider)));
  }

  /// Tiền mà giảm cả đơn áp lên, đúng như calcCart.
  static int _baseVnd(CartState cart) =>
      cart.totals.subtotalVnd - cart.totals.lineDiscountVnd;

  void _applyDiscount(int baseVnd) {
    final notifier = ref.read(cartProvider.notifier);
    final cart = ref.read(cartProvider);
    final vnd = _discountVnd ?? 0;

    String? error;
    var bp = 0;
    if (cart.isEmpty) {
      bp = 0;
    } else if (vnd > baseVnd) {
      // Không kẹp: báo lỗi, bỏ giảm và tắt Thu tiền cho tới khi sửa số.
      error = CartPanel.overSubtotalError;
    } else {
      bp = vndToOrderBp(vnd, baseVnd);
    }

    if (cart.orderDiscountBp != bp) {
      notifier.setOrderDiscountBp(bp);
    }
    notifier.setOrderDiscountRejected(error != null);
    if (error != _discountError && mounted) {
      setState(() => _discountError = error);
    }
  }

  void _toggleExpanded() {
    if (_expanded) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(cartProvider.select(_baseVnd), (_, next) {
      if (ref.read(cartProvider).isEmpty) {
        _discountVnd = null;
        _discountController.clear();
      }
      _applyDiscount(next);
    });

    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    return Material(
      color: AppColors.surface,
      shape: const Border(top: BorderSide(color: AppColors.border)),
      child: Column(
        mainAxisSize: _expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SelectedHeader(
            count: cart.itemCount,
            expanded: _expanded,
            onToggle: _toggleExpanded,
          ),
          if (_expanded)
            Expanded(
              child: _LineList(
                footer: Padding(
                  padding: const EdgeInsets.all(AppSpacing.padding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AmountRow(
                        label: CartPanel.subtotalLabel,
                        amount: _baseVnd(cart),
                      ),
                      const SizedBox(height: AppSpacing.padding),
                      // Nhãn dùng bodyLarge để chữ trên màn bán không dưới 16.
                      const Text(
                        CartPanel.discountLabel,
                        style: AppTypography.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.radius),
                      AppTextField(
                        key: CartPanel.discountFieldKey,
                        controller: _discountController,
                        kind: AppTextFieldKind.money,
                        onMoneyChanged: _onDiscountChanged,
                      ),
                      if (_discountError != null)
                        Text(
                          _discountError!,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      if (cart.totals.orderDiscountVnd > 0) ...[
                        const SizedBox(height: AppSpacing.radius),
                        _AmountRow(
                          label: CartPanel.appliedLabel,
                          amount: cart.totals.orderDiscountVnd,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else if (_discountError != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.padding,
              ),
              child: Text(
                _discountError!,
                style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedHeader extends StatelessWidget {
  const _SelectedHeader({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tooltip = expanded
        ? CartPanel.collapseTooltip
        : CartPanel.expandTooltip;
    return Semantics(
      button: true,
      expanded: expanded,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.padding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      CartPanel.selectedLabel(count),
                      style: AppTypography.bodyLarge,
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_more : Icons.expand_less,
                    size: AppSpacing.icon,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineList extends ConsumerStatefulWidget {
  const _LineList({required this.footer});

  final Widget footer;

  @override
  ConsumerState<_LineList> createState() => _LineListState();
}

class _LineListState extends ConsumerState<_LineList> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scrollbar(
      controller: _controller,
      child: ListView.builder(
        key: CartPanel.lineListKey,
        controller: _controller,
        primary: false,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: cart.lines.length + 1,
        itemBuilder: (context, index) {
          if (index == cart.lines.length) {
            return KeyedSubtree(
              key: const ValueKey('cart-discount-footer'),
              child: widget.footer,
            );
          }
          final notifier = ref.read(cartProvider.notifier);
          return CartLineTile(
            key: ValueKey(index),
            line: cart.lines[index],
            onIncrement: () => notifier.increment(index),
            onDecrement: () => notifier.decrement(index),
          );
        },
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTypography.bodyLarge),
        const SizedBox(width: AppSpacing.padding),
        Expanded(child: MoneyText(amount)),
      ],
    );
  }
}
