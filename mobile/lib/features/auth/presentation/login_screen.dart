import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/app_text_field.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const String devAccessToken = 'dev-token';
const String serverNotConnectedLabel = 'Chưa nối máy chủ';

final RegExp _sixDigits = RegExp(r'^[0-9]{6}$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _otp = TextEditingController();
  String? _otpError;
  String? _saveError;
  bool _saving = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || ref.read(appEnvProvider).isProd) return;
    final otp = _otp.text;
    if (otp.length != 6 || !_sixDigits.hasMatch(otp)) {
      setState(() {
        _otpError = 'Mã gồm đúng 6 chữ số.';
        _saveError = null;
      });
      return;
    }

    setState(() {
      _saving = true;
      _otpError = null;
      _saveError = null;
    });
    try {
      await ref.read(tokenStorageProvider).saveAccessToken(devAccessToken);
      if (!mounted) return;
      context.go(AppRoutes.sales);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Chưa lưu được đăng nhập. Bạn bấm Thử lại nhé.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProd = ref.watch(appEnvProvider).isProd;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.padding),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nhập mã xác nhận',
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.padding),
                  AppTextField(
                    controller: _otp,
                    label: 'Mã 6 số',
                    hint: '000000',
                    errorText: _otpError,
                    keyboardType: TextInputType.number,
                    enabled: !isProd && !_saving,
                    onChanged: (_) {
                      if (_otpError != null || _saveError != null) {
                        setState(() {
                          _otpError = null;
                          _saveError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.padding),
                  PrimaryButton(
                    label: _saveError == null ? 'Đăng nhập' : 'Thử lại',
                    isLoading: _saving,
                    // Prod chưa có máy chủ thật: nút tắt, không có đường lưu token.
                    onPressed: isProd ? null : _submit,
                  ),
                  if (isProd) ...[
                    const SizedBox(height: AppSpacing.padding),
                    const Text(
                      serverNotConnectedLabel,
                      style: AppTypography.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_saveError != null) ...[
                    const SizedBox(height: AppSpacing.padding),
                    Text(
                      _saveError!,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
