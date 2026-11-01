import 'package:intl/intl.dart';

/// Định dạng tiền VND (số nguyên, không dùng double).
///
/// Dùng `intl` với locale `vi_VN` để nhóm hàng nghìn, rồi ép dấu ngăn cách
/// về `.` để mọi máy đều hiện `1.250.000` — không phụ thuộc locale thiết bị.
abstract final class MoneyFormat {
  static final NumberFormat _decimal = NumberFormat.decimalPattern('vi_VN');

  static const String symbol = '₫';

  /// `1250000` → `1.250.000 ₫`. Số âm: `-1.250.000 ₫`.
  static String format(int amount) {
    final sign = amount < 0 ? '-' : '';
    return '$sign${group(amount.abs())} $symbol';
  }

  /// Phần số cho ô nhập, không kèm ký hiệu: `1250000` → `1.250.000`.
  static String group(int amount) {
    final raw = _decimal.format(amount.abs());
    return raw.replaceAll(RegExp(r'[,\s\u00A0\u202F]'), '.');
  }

  /// `1.250.000` → `1250000`. Rỗng → null. Cắt ở 15 chữ số để không tràn int.
  static int? parseDigits(String text) {
    final digits = text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return null;
    final capped = digits.length > 15 ? digits.substring(0, 15) : digits;
    return int.tryParse(capped);
  }
}
