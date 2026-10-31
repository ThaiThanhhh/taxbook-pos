/// Hằng số dùng chung toàn app. Không đặt hằng số nghiệp vụ/thuế ở đây —
/// tham số thuế lấy từ `config/tax/` (xem PROJECT_STRUCTURE.md).
abstract final class AppConstants {
  static const String appName = 'ĐT13 POS';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
