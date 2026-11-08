import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// F04 – Cài đặt: đăng xuất.
///
/// Đăng xuất CHỈ xoá token qua [tokenStorageProvider] rồi về màn đăng nhập.
/// Không đụng DB cục bộ: đơn hàng chưa đồng bộ vẫn phải còn trên máy.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Thông báo lỗi đã làm sạch — không bao giờ hiện chi tiết exception.
  static const String logoutErrorMessage =
      'Không thể đăng xuất. Vui lòng thử lại.';

  bool _isLoggingOut = false;
  bool _hasError = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
      _hasError = false;
    });

    try {
      await ref.read(tokenStorageProvider).clear();
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
        _hasError = true;
      });
      return;
    }

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: _hasError
          ? ErrorState(
              title: 'Đăng xuất chưa thành công',
              message: logoutErrorMessage,
              onRetry: _logout,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.padding),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tài khoản',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.padding / 2),
                      Text(
                        'Đăng xuất khỏi thiết bị này. Đơn hàng chưa đồng bộ '
                        'vẫn được giữ trên máy.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.padding),
                      PrimaryButton(
                        label: 'Đăng xuất',
                        isLoading: _isLoggingOut,
                        onPressed: _isLoggingOut ? null : _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
