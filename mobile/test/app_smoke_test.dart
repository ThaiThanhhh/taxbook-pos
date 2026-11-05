import 'dart:async';

import 'package:dt13_pos/app.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/core/router/app_router.dart';
import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/features/auth/presentation/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _testEnv = AppEnv(
  flavor: Flavor.dev,
  apiBaseUrl: 'http://localhost:3000/api/v1',
  enableHttpLog: false,
);

final class _PendingTokenStorage implements TokenStorage {
  final Completer<String?> read = Completer<String?>();
  int readCalls = 0;

  @override
  Future<String?> readAccessToken() {
    readCalls++;
    return read.future;
  }

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final platformRoute in [AppRoutes.login, AppRoutes.sales]) {
    testWidgets('f04_app_router_ignores_platform_route_$platformRoute', (
      tester,
    ) async {
      tester.platformDispatcher.defaultRouteNameTestValue = platformRoute;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final storage = _PendingTokenStorage();
      final container = ProviderContainer(
        overrides: [
          appEnvProvider.overrideWithValue(_testEnv),
          tokenStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const Dt13App()),
      );
      await tester.pump();

      final router = container.read(appRouterProvider);
      expect(router.state.uri.path, AppRoutes.splash);
      expect(find.byType(LoginScreen), findsNothing);
      expect(storage.readCalls, 1);

      storage.read.complete('dev-token');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.sales);
      expect(find.byType(LoginScreen), findsNothing);
    });
  }

  testWidgets('App đọc token tại /splash rồi mở /login khi chưa đăng nhập', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [appEnvProvider.overrideWithValue(_testEnv)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const Dt13App()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.login);

    container.read(appRouterProvider).go(AppRoutes.sales);
    await tester.pumpAndSettle();

    expect(find.text('Bán hàng'), findsOneWidget);
    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.sales);
  });

  test('Mọi route khai báo trong AppRoutes đều có trong GoRouter', () {
    final container = ProviderContainer(
      overrides: [appEnvProvider.overrideWithValue(_testEnv)],
    );
    addTearDown(container.dispose);

    final paths = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((r) => r.path)
        .toSet();

    expect(paths, containsAll(AppRoutes.all));
    expect(kDebugMode, isTrue);
    expect(paths, contains(AppRoutes.designGallery));
  });

  test('ApiClient dùng baseUrl theo môi trường', () {
    final container = ProviderContainer(
      overrides: [appEnvProvider.overrideWithValue(_testEnv)],
    );
    addTearDown(container.dispose);

    final client = container.read(apiClientProvider);
    expect(client.dio.options.baseUrl, _testEnv.apiBaseUrl);
  });
}
