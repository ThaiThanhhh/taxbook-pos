import 'package:dt13_pos/core/constants/app_constants.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/router/app_router.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Dt13App extends ConsumerWidget {
  const Dt13App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final env = ref.watch(appEnvProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: !env.isProd,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
