import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_env.g.dart';

/// Môi trường build. Chọn bằng `--dart-define-from-file=config/env/<flavor>.json`.
enum Flavor { dev, staging, prod }

/// Cấu hình đọc từ `--dart-define` lúc compile (không đọc file lúc runtime,
/// nên không lộ cấu hình trong assets và tree-shake được theo môi trường).
@immutable
class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.enableHttpLog,
  });

  factory AppEnv.fromDartDefine() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      // 10.0.2.2 = localhost của máy host khi chạy Android emulator.
      defaultValue: 'http://10.0.2.2:3000/api/v1',
    );
    const enableHttpLog = bool.fromEnvironment(
      'ENABLE_HTTP_LOG',
      defaultValue: true,
    );

    final flavor = Flavor.values.firstWhere(
      (f) => f.name == flavorName,
      orElse: () => throw StateError(
        'FLAVOR không hợp lệ: "$flavorName". Dùng dev | staging | prod.',
      ),
    );

    return AppEnv(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      // Prod không bao giờ log HTTP, kể cả khi cấu hình nhầm.
      enableHttpLog: enableHttpLog && flavor != Flavor.prod,
    );
  }

  final Flavor flavor;
  final String apiBaseUrl;
  final bool enableHttpLog;

  bool get isProd => flavor == Flavor.prod;
}

/// Override trong test bằng `appEnvProvider.overrideWithValue(...)`.
@Riverpod(keepAlive: true)
AppEnv appEnv(Ref ref) => AppEnv.fromDartDefine();
