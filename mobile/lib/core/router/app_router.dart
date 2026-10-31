import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/features/auth/presentation/login_screen.dart';
import 'package:dt13_pos/features/auth/presentation/splash_screen.dart';
import 'package:dt13_pos/features/payment/presentation/payment_screen.dart';
import 'package:dt13_pos/features/sales/presentation/sales_history_screen.dart';
import 'package:dt13_pos/features/sales/presentation/sales_screen.dart';
import 'package:dt13_pos/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Router là provider để sau này `redirect` có thể `ref.watch` trạng thái
/// đăng nhập (dùng `refreshListenable`). Hiện chưa có redirect.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.splash),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.sales, builder: (_, _) => const SalesScreen()),
      GoRoute(
        path: AppRoutes.payment,
        builder: (_, _) => const PaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, _) => const SalesHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Không tìm thấy trang: ${state.uri}')),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
}
