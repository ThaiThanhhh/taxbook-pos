import 'package:dt13_pos/app.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/router/app_router.dart';
import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _testEnv = AppEnv(
  flavor: Flavor.dev,
  apiBaseUrl: 'http://localhost:3000/api/v1',
  enableHttpLog: false,
);

void main() {
  testWidgets('App khởi động ở /splash và điều hướng được tới /sales', (
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

    expect(find.text('ĐT13 POS'), findsOneWidget);
    expect(find.text('Placeholder: ${AppRoutes.splash}'), findsOneWidget);

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
