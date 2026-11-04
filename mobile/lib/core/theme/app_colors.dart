import 'package:flutter/material.dart';

/// Bảng màu ĐT13 POS, khai báo tường minh — không sinh từ [ColorScheme.fromSeed].
///
/// Các mã Primary / Success / Error / Warning / nền / chữ / viền nhẹ là chuẩn
/// nhóm đã chốt. [inputBorder], màu chữ phụ và màu disabled là đề xuất
/// (xem ghi chú trên từng hằng số) — cần xác nhận lại với nhóm.
abstract final class AppColors {
  /// Xanh đậm thương hiệu. Trắng trên màu này đạt khoảng 7.9:1 (WCAG AAA).
  static const Color primary = Color(0xFF145C4B);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Nền nút phụ: cùng họ với primary, nhạt để phân biệt với nút chính
  /// mà chữ primary vẫn đọc rõ (không bịa thêm một màu thương hiệu thứ hai).
  static const Color primaryContainer = Color(0xFFD7EDE6);
  static const Color onPrimaryContainer = Color(0xFF0B3D32);

  static const Color success = Color(0xFF1F7A4D);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFE5F5EC);

  static const Color error = Color(0xFFB42318);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFDECEA);

  static const Color warning = Color(0xFFB54708);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF4E6);

  static const Color background = Color(0xFFF7F9F8);
  static const Color surface = Color(0xFFFFFFFF);

  /// Chữ chính trên nền trắng: #1D2939, tương phản rất cao.
  static const Color textPrimary = Color(0xFF1D2939);

  /// Chữ phụ / gợi ý. #475467 trên trắng khoảng 7:1 — vẫn đọc được với
  /// người lớn tuổi. Không dùng xám nhạt (#98A2B3, chỉ khoảng 2.7:1).
  static const Color textSecondary = Color(0xFF475467);

  /// Viền card, vạch ngăn. Nhạt, chỉ để tách khối — không đủ tương phản
  /// cho viền ô nhập (khoảng 1.5:1 trên trắng, dưới ngưỡng 3:1 của WCAG).
  static const Color border = Color(0xFFD0D5DD);

  /// Viền ô nhập. Đề xuất #667085: khoảng 5:1 trên trắng, đạt ngưỡng 3:1
  /// cho thành phần giao diện. Đậm hơn [border] đúng yêu cầu nhóm.
  /// Cần xác nhận trước khi coi là chốt.
  static const Color inputBorder = Color(0xFF667085);

  /// Nền control tắt. Chữ tắt dùng [textSecondary] chứ không dùng xám nhạt,
  /// để nhãn nút disabled vẫn đọc được ngoài quầy.
  static const Color disabledBackground = Color(0xFFE4E7EC);
  static const Color onDisabled = textSecondary;

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: primary,
    onSecondary: onPrimary,
    secondaryContainer: primaryContainer,
    onSecondaryContainer: onPrimaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: Color(0xFF7A150E),
    surface: surface,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    outline: inputBorder,
    outlineVariant: border,
    surfaceContainerLowest: surface,
    surfaceContainerLow: background,
    surfaceContainer: background,
    surfaceContainerHigh: Color(0xFFEEF2F0),
    surfaceContainerHighest: Color(0xFFE4E7EC),
  );

  /// Bản tối dự phòng, KHÔNG dùng fromSeed. App đang khóa [ThemeMode.light]
  /// vì widget dùng chung đọc token sáng. Chưa chốt với nhóm — đừng bật
  /// dark mode trước khi rà lại tương phản.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8FCBB8),
    onPrimary: Color(0xFF083028),
    primaryContainer: Color(0xFF145C4B),
    onPrimaryContainer: Color(0xFFD7EDE6),
    secondary: Color(0xFF8FCBB8),
    onSecondary: Color(0xFF083028),
    secondaryContainer: Color(0xFF145C4B),
    onSecondaryContainer: Color(0xFFD7EDE6),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF8C1D13),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1D2939),
    onSurface: Color(0xFFF7F9F8),
    onSurfaceVariant: Color(0xFFD0D5DD),
    outline: Color(0xFF98A2B3),
    outlineVariant: Color(0xFF344054),
  );
}
