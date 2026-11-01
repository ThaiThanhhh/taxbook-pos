import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// `regular` = 48 dp. `large` = 52 dp — dùng cho nút thanh toán chính.
enum AppButtonSize {
  regular(AppSpacing.buttonHeight),
  large(AppSpacing.buttonHeightLarge);

  const AppButtonSize(this.height);

  final double height;
}

enum AppButtonVariant { primary, secondary, outline }

/// Nút gốc. Màn hình dùng [PrimaryButton], [SecondaryButton], [OutlineButton].
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.variant,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.regular,
    this.expanded = false,
    super.key,
  });

  final String label;
  final AppButtonVariant variant;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = _style();
    final spinnerColor = variant == AppButtonVariant.primary
        ? AppColors.onPrimary
        : AppColors.primary;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: onPressed == null ? AppColors.onDisabled : spinnerColor,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(label),
      ],
    );

    final button = switch (variant) {
      AppButtonVariant.outline => OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      _ => FilledButton(onPressed: onPressed, style: style, child: child),
    };

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: isLoading ? '$label, đang xử lý' : label,
      child: AbsorbPointer(
        absorbing: isLoading,
        child: ExcludeSemantics(
          child: expanded
              ? SizedBox(width: double.infinity, child: button)
              : button,
        ),
      ),
    );
  }

  ButtonStyle _style() {
    final height = size.height;
    const radius = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
    );

    final (
      Color foreground,
      Color background,
      BorderSide resting,
    ) = switch (variant) {
      AppButtonVariant.primary => (
        AppColors.onPrimary,
        AppColors.primary,
        BorderSide.none,
      ),
      AppButtonVariant.secondary => (
        AppColors.primary,
        AppColors.primaryContainer,
        BorderSide.none,
      ),
      AppButtonVariant.outline => (
        AppColors.primary,
        AppColors.surface,
        const BorderSide(
          color: AppColors.primary,
          width: AppSpacing.borderWidth,
        ),
      ),
    };

    final focusColor = variant == AppButtonVariant.primary
        ? AppColors.onPrimary
        : AppColors.primary;

    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.padding),
      ),
      minimumSize: WidgetStatePropertyAll(
        Size(AppSpacing.minTapTarget, height),
      ),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, height)),
      textStyle: const WidgetStatePropertyAll(AppTypography.button),
      shape: const WidgetStatePropertyAll(radius),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.onDisabled;
        return foreground;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.disabledBackground;
        }
        return background;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: AppColors.border);
        }
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return BorderSide(
            color: focusColor,
            width: AppSpacing.focusBorderWidth,
          );
        }
        return resting;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return focusColor.withValues(alpha: 0.16);
        }
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered)) {
          return focusColor.withValues(alpha: 0.08);
        }
        return null;
      }),
    );
  }
}
