import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Theme Material 3 dùng chung. Màu lấy từ [AppColors], không dùng fromSeed.
///
/// Mai Trinh sở hữu design system. Màn bán hàng (ô sản phẩm, dòng giỏ,
/// bàn phím tiền) không đặt ở đây — xem `features/sales`.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.lightScheme, Brightness.light);

  static ThemeData dark() => _build(AppColors.darkScheme, Brightness.dark);

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final onSurface = scheme.onSurface;
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? AppColors.background : scheme.surface,
      textTheme: textTheme,
      primaryTextTheme: AppTypography.textTheme.apply(
        bodyColor: scheme.onPrimary,
        displayColor: scheme.onPrimary,
      ),
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: onSurface, size: AppSpacing.icon),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: scheme.onPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: _inputDecoration(scheme),
      filledButtonTheme: FilledButtonThemeData(style: _filledStyle(scheme)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlineStyle(scheme),
      ),
    );
  }

  static InputDecorationThemeData _inputDecoration(ColorScheme scheme) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSpacing.radius),
        ),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.padding,
        vertical: AppSpacing.padding,
      ),
      hintStyle: AppTypography.bodyLarge.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      errorStyle: AppTypography.labelMedium.copyWith(color: scheme.error),
      enabledBorder: border(scheme.outline, AppSpacing.borderWidth),
      focusedBorder: border(scheme.primary, AppSpacing.focusBorderWidth),
      errorBorder: border(scheme.error, AppSpacing.borderWidth),
      focusedErrorBorder: border(scheme.error, AppSpacing.focusBorderWidth),
      disabledBorder: border(scheme.outlineVariant, AppSpacing.borderWidth),
    );
  }

  static ButtonStyle _filledStyle(ColorScheme scheme) {
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(
        Size(AppSpacing.minTapTarget, AppSpacing.buttonHeight),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const WidgetStatePropertyAll(AppTypography.button),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
      backgroundColor: WidgetStatePropertyAll(scheme.primary),
    );
  }

  static ButtonStyle _outlineStyle(ColorScheme scheme) {
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(
        Size(AppSpacing.minTapTarget, AppSpacing.buttonHeight),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const WidgetStatePropertyAll(AppTypography.button),
      foregroundColor: WidgetStatePropertyAll(scheme.primary),
      side: WidgetStatePropertyAll(
        BorderSide(color: scheme.primary, width: AppSpacing.borderWidth),
      ),
    );
  }
}
