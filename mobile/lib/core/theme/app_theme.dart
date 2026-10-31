import 'package:flutter/material.dart';

/// Theme gốc. Mai Trinh sở hữu phần design system (chữ lớn, tương phản cao);
/// file này chỉ là điểm vào để cả app dùng chung một theme.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF0B6E4F);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    visualDensity: VisualDensity.standard,
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );
}
