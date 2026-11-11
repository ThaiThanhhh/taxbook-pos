/// Đường dẫn route dùng chung. Luôn dùng hằng số này, không hard-code chuỗi.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String sales = '/sales';
  static const String payment = '/payment';
  static const String history = '/history';
  static const String settings = '/settings';

  /// Chỉ đăng ký trong bản debug. Không nằm trong [all] để test route
  /// và bản phát hành không bắt buộc phải có màn này.
  static const String designGallery = '/design-gallery';

  static const List<String> all = [
    splash,
    login,
    welcome,
    onboarding,
    sales,
    payment,
    history,
    settings,
  ];
}
