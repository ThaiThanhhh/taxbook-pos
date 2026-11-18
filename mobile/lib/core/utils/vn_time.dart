/// Giờ Việt Nam (Asia/Ho_Chi_Minh). Dart thuần.
///
/// Việt Nam dùng UTC+7 cố định, không đổi giờ theo mùa, nên cộng 7 giờ là
/// đúng và không cần nạp dữ liệu múi giờ.
library;

/// Độ lệch của Asia/Ho_Chi_Minh so với UTC.
const Duration kVietnamUtcOffset = Duration(hours: 7);

/// Ngày `yyMMdd` theo giờ Việt Nam của thời điểm [instant].
///
/// Ví dụ 2026-11-13T17:00:00Z là 00:00 ngày 14/11 ở Việt Nam -> `261114`.
String vnDayKey(DateTime instant) {
  final vn = instant.toUtc().add(kVietnamUtcOffset);
  return '${_two(vn.year % 100)}${_two(vn.month)}${_two(vn.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
