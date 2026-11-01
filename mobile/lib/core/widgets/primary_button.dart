import 'package:dt13_pos/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Nút chính. Cao 48; nút thanh toán dùng [AppButtonSize.large] (52).
/// [onPressed] null = disabled. [isLoading] hiện vòng tròn và chặn bấm lặp.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.regular,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      expanded: expanded,
      variant: AppButtonVariant.primary,
    );
  }
}
