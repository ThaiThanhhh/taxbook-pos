/// Đường dẫn route dùng chung. Luôn dùng hằng số này, không hard-code chuỗi.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String sales = '/sales';
  static const String payment = '/payment';
  static const String history = '/history';
  static const String settings = '/settings';

  static const List<String> all = [
    splash,
    login,
    sales,
    payment,
    history,
    settings,
  ];
}
