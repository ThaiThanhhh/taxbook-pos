import 'dart:async';

import 'package:dt13_pos/core/db/local_database.dart';
import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _loginStubText = 'LOGIN_STUB';
const _secretError = 'SecureStorage keystore failure: token=abc123';

/// TokenStorage giả: ghi lại thứ tự sự kiện; [onClear] quyết định kết quả.
class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage(this.events, {required this.onClear});

  final List<String> events;
  Future<void> Function(int call) onClear;
  int clearCalls = 0;

  @override
  Future<String?> readAccessToken() async => 'token';

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> clear() async {
    clearCalls++;
    events.add('clear:start');
    await onClear(clearCalls);
    events.add('clear:done');
  }
}

class _Harness {
  _Harness(this.router, this.storage);

  final GoRouter router;
  final _FakeTokenStorage storage;
  int dbReads = 0;

  String get path => router.state.uri.path;
}

Future<_Harness> _pumpSettings(
  WidgetTester tester, {
  required Future<void> Function(int call) onClear,
}) async {
  final events = <String>[];
  final storage = _FakeTokenStorage(events, onClear: onClear);
  final router = GoRouter(
    initialLocation: AppRoutes.settings,
    routes: [
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) {
          events.add('route:login');
          return const Scaffold(body: Text(_loginStubText));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  final harness = _Harness(router, storage);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        // Chứng minh đăng xuất không chạm DB: mọi lần đọc đều bị đếm và ném lỗi.
        localDatabaseProvider.overrideWith((ref) {
          harness.dbReads++;
          throw StateError('LocalDatabase must not be used by logout');
        }),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

Finder get _logoutButton => find.text('Đăng xuất');

void main() {
  testWidgets('Đăng xuất thành công: xoá token rồi mới về /login', (
    tester,
  ) async {
    final h = await _pumpSettings(tester, onClear: (_) async {});

    expect(find.text('Cài đặt'), findsOneWidget);
    await tester.tap(_logoutButton);
    await tester.pumpAndSettle();

    expect(h.storage.clearCalls, 1);
    expect(h.path, AppRoutes.login);
    expect(find.text(_loginStubText), findsOneWidget);
    expect(h.storage.events, ['clear:start', 'clear:done', 'route:login']);
    expect(h.dbReads, 0);
  });

  testWidgets('Đang xoá token: ở lại Cài đặt, chặn bấm lặp', (tester) async {
    final completer = Completer<void>();
    final h = await _pumpSettings(tester, onClear: (_) => completer.future);

    await tester.tap(_logoutButton);
    await tester.pump();

    expect(h.storage.clearCalls, 1);
    expect(h.path, AppRoutes.settings);
    expect(find.text(_loginStubText), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Bấm lặp khi đang tải không gọi clear lần nữa.
    await tester.tap(_logoutButton, warnIfMissed: false);
    await tester.pump();
    expect(h.storage.clearCalls, 1);
    expect(h.storage.events, ['clear:start']);

    completer.complete();
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.login);
    expect(find.text(_loginStubText), findsOneWidget);
    expect(h.storage.clearCalls, 1);
    expect(h.dbReads, 0);
  });

  testWidgets('Lỗi xoá token: hiện lỗi đã làm sạch, Thử lại mới về /login', (
    tester,
  ) async {
    final retryCompleter = Completer<void>();
    final h = await _pumpSettings(
      tester,
      onClear: (call) async {
        if (call == 1) throw Exception(_secretError);
        await retryCompleter.future;
      },
    );

    await tester.tap(_logoutButton);
    await tester.pumpAndSettle();

    expect(h.storage.clearCalls, 1);
    expect(h.path, AppRoutes.settings);
    expect(find.text(_loginStubText), findsNothing);
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('abc123'), findsNothing);
    expect(find.textContaining('keystore'), findsNothing);
    expect(h.storage.events, isNot(contains('route:login')));

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    // Thử lại đang chờ clear: chưa được rời màn Cài đặt.
    expect(h.storage.clearCalls, 2);
    expect(h.path, AppRoutes.settings);
    expect(find.text(_loginStubText), findsNothing);

    retryCompleter.complete();
    await tester.pumpAndSettle();

    expect(h.storage.clearCalls, 2);
    expect(h.path, AppRoutes.login);
    expect(find.text(_loginStubText), findsOneWidget);
    expect(h.storage.events.last, 'route:login');
    expect(h.dbReads, 0);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'Rời Cài đặt khi clear đang chờ: ${fails ? 'lỗi' : 'thành công'} '
      'không cập nhật widget đã huỷ',
      (tester) async {
        final completer = Completer<void>();
        final h = await _pumpSettings(tester, onClear: (_) => completer.future);

        await tester.tap(_logoutButton);
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());

        if (fails) {
          completer.completeError(Exception(_secretError));
        } else {
          completer.complete();
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(h.path, AppRoutes.settings);
        expect(h.storage.events, isNot(contains('route:login')));
        expect(h.dbReads, 0);
      },
    );
  }
}
