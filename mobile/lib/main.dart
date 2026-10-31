import 'package:dt13_pos/app.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chạy với: flutter run --dart-define-from-file=config/env/dev.json
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final env = AppEnv.fromDartDefine();
  AppLogger.d('Start flavor=${env.flavor.name} api=${env.apiBaseUrl}');

  runApp(
    ProviderScope(
      overrides: [appEnvProvider.overrideWithValue(env)],
      child: const Dt13App(),
    ),
  );
}
