import 'dart:async';

import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/features/auth/presentation/login_screen.dart';
import 'package:dt13_pos/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this._read, this._save});

  String? token;
  final Future<String?> Function()? _read;
  final Future<void> Function()? _save;
  final List<String> saved = [];
  int readCalls = 0;
  int saveCalls = 0;

  @override
  Future<String?> readAccessToken() {
    readCalls++;
    return _read?.call() ?? Future.value(token);
  }

  @override
  Future<void> saveAccessToken(String value) async {
    saveCalls++;
    await _save?.call();
    saved.add(value);
    token = value;
  }

  @override
  Future<void> clear() async => token = null;
}

AppEnv _env(Flavor flavor) => AppEnv(
  flavor: flavor,
  apiBaseUrl: 'http://localhost',
  enableHttpLog: false,
);

Future<(GoRouter, List<String>)> _pump(
  WidgetTester tester, {
  required TokenStorage storage,
  String initial = AppRoutes.splash,
  Flavor flavor = Flavor.dev,
}) async {
  final visits = <String>[];
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) {
          visits.add(AppRoutes.splash);
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) {
          visits.add(AppRoutes.login);
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.sales,
        builder: (_, _) {
          visits.add(AppRoutes.sales);
          return const Scaffold(body: Text('SALES_STUB'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appEnvProvider.overrideWithValue(_env(flavor)),
        tokenStorageProvider.overrideWithValue(storage),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  return (router, visits);
}

Finder get _loginButton => find.widgetWithText(FilledButton, 'Đăng nhập');

Future<void> _submitOtp(WidgetTester tester, String otp) async {
  await tester.enterText(find.byType(TextField), otp);
  await tester.tap(_loginButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('f04_splash_token_waits_then_sales_without_login', (
    tester,
  ) async {
    final read = Completer<String?>();
    final storage = _FakeTokenStorage(read: () => read.future);
    final (router, visits) = await _pump(tester, storage: storage);
    await tester.pump();

    expect(router.state.uri.path, AppRoutes.splash);
    expect(visits, [AppRoutes.splash]);
    read.complete(devAccessToken);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.sales);
    expect(visits, isNot(contains(AppRoutes.login)));
    expect(storage.readCalls, 1);
  });

  testWidgets('f04_splash_without_token_goes_login', (tester) async {
    final storage = _FakeTokenStorage();
    final (router, _) = await _pump(tester, storage: storage);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.login);
  });

  testWidgets('f04_splash_read_error_retries', (tester) async {
    var attempts = 0;
    final storage = _FakeTokenStorage(
      read: () async {
        attempts++;
        if (attempts == 1) throw Exception('keystore=secret');
        return null;
      },
    );
    final (router, _) = await _pump(tester, storage: storage);
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(router.state.uri.path, AppRoutes.splash);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.login);
  });

  for (final flavor in [Flavor.dev, Flavor.staging]) {
    testWidgets('f04_${flavor.name}_six_digits_saves_dev_token', (
      tester,
    ) async {
      final storage = _FakeTokenStorage();
      final (router, _) = await _pump(
        tester,
        storage: storage,
        initial: AppRoutes.login,
        flavor: flavor,
      );
      await tester.pumpAndSettle();
      await _submitOtp(tester, '123456');

      expect(storage.saved, ['dev-token']);
      expect(router.state.uri.path, AppRoutes.sales);
    });
  }

  testWidgets('f04_five_digits_does_not_save', (tester) async {
    final storage = _FakeTokenStorage();
    final (router, _) = await _pump(
      tester,
      storage: storage,
      initial: AppRoutes.login,
    );
    await tester.pumpAndSettle();
    await _submitOtp(tester, '12345');

    expect(storage.saved, isEmpty);
    expect(router.state.uri.path, AppRoutes.login);
    expect(find.text('Mã gồm đúng 6 chữ số.'), findsOneWidget);
  });

  testWidgets('f04_invalid_otp_variants_do_not_save', (tester) async {
    final storage = _FakeTokenStorage();
    await _pump(tester, storage: storage, initial: AppRoutes.login);
    await tester.pumpAndSettle();
    for (final otp in ['1234567', '12345a', ' 123456', '١٢٣٤٥٦']) {
      await _submitOtp(tester, otp);
      expect(storage.saved, isEmpty, reason: otp);
    }
  });

  testWidgets('f04_prod_does_not_save_and_shows_not_connected', (tester) async {
    final storage = _FakeTokenStorage();
    final (router, _) = await _pump(
      tester,
      storage: storage,
      initial: AppRoutes.login,
      flavor: Flavor.prod,
    );
    await tester.pumpAndSettle();

    expect(find.text(serverNotConnectedLabel), findsOneWidget);
    expect(tester.widget<FilledButton>(_loginButton).onPressed, isNull);
    await tester.tap(_loginButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(storage.saveCalls, 0);
    expect(storage.saved, isEmpty);
    expect(router.state.uri.path, AppRoutes.login);
  });

  testWidgets('f04_login_waits_for_save_and_blocks_duplicate', (tester) async {
    final pending = Completer<void>();
    final storage = _FakeTokenStorage(save: () => pending.future);
    final (router, _) = await _pump(
      tester,
      storage: storage,
      initial: AppRoutes.login,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(_loginButton);
    await tester.pump();
    expect(router.state.uri.path, AppRoutes.login);
    expect(storage.saved, isEmpty);
    expect(storage.saveCalls, 1);
    await tester.tap(_loginButton, warnIfMissed: false);
    await tester.pump();
    expect(storage.saveCalls, 1);

    pending.complete();
    await tester.pumpAndSettle();
    expect(storage.saved, ['dev-token']);
    expect(router.state.uri.path, AppRoutes.sales);
  });

  testWidgets('f04_login_storage_error_can_retry', (tester) async {
    var attempts = 0;
    final storage = _FakeTokenStorage(
      save: () async {
        attempts++;
        if (attempts == 1) throw Exception('secret=do-not-display');
      },
    );
    final (router, _) = await _pump(
      tester,
      storage: storage,
      initial: AppRoutes.login,
    );
    await tester.pumpAndSettle();
    await _submitOtp(tester, '123456');
    expect(router.state.uri.path, AppRoutes.login);
    expect(storage.saved, isEmpty);
    expect(find.textContaining('do-not-display'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Thử lại'));
    await tester.pumpAndSettle();
    expect(storage.saveCalls, 2);
    expect(storage.saved, ['dev-token']);
    expect(router.state.uri.path, AppRoutes.sales);
  });

  testWidgets('f04_login_tap_target_and_text_size', (tester) async {
    await _pump(tester, storage: _FakeTokenStorage(), initial: AppRoutes.login);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
    final text = tester.widget<Text>(find.text('Nhập mã xác nhận'));
    expect(text.style?.fontSize, greaterThanOrEqualTo(16));
  });
}
