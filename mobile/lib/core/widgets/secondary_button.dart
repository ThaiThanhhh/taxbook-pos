import 'package:dt13_pos/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Nút phụ: nền xanh nhạt, chữ primary. Cao 48, elevation 0.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
      variant: AppButtonVariant.secondary,
    );
  }
}
