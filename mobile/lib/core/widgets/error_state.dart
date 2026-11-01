import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';

/// Lỗi có nút thử lại. Icon + chữ + nút — không chỉ dựa vào màu đỏ.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    required this.onRetry,
    this.title = 'Đã có lỗi',
    this.retryLabel = 'Thử lại',
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String title;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
