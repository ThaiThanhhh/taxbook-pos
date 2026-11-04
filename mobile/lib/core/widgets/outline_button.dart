import 'package:dt13_pos/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Nút viền 1 dp, nền trong. Focus/pressed dày 2 dp — không chỉ đổi màu.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.regular,
    this.expanded = false,
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
      variant: AppButtonVariant.outline,
    );
  }
}
