import 'dart:async';

import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_openSession());
  }

  Future<void> _openSession() async {
    try {
      final token = await ref.read(tokenStorageProvider).readAccessToken();
      if (!mounted) return;
      // Không điều hướng mặc định: chỉ chọn đích khi đã đọc xong kho khóa.
      context.go(
        token != null && token.isNotEmpty ? AppRoutes.sales : AppRoutes.login,
      );
    } on Exception {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    unawaited(_openSession());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ĐT13 POS', style: AppTypography.titleLarge),
      ),
      body: _failed
          ? ErrorState(
              message: 'Chưa đọc được phiên đăng nhập. Bạn thử lại nhé.',
              onRetry: _retry,
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.padding),
                  Text('Đang mở sổ bán hàng', style: AppTypography.bodyLarge),
                ],
              ),
            ),
    );
  }
}
