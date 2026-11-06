import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Trạng thái đồng bộ dùng chung cho đơn hàng và hóa đơn.
/// Icon + chữ, không truyền trạng thái chỉ bằng màu.
enum SyncStatus { synced, pending, failed }

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {this.onTap, super.key});

  final SyncStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = switch (status) {
      SyncStatus.synced => (
        label: 'Đã đồng bộ',
        icon: Icons.check_circle,
        foreground: AppColors.success,
        background: AppColors.successContainer,
      ),
      SyncStatus.pending => (
        label: 'Chờ gửi',
        icon: Icons.schedule,
        foreground: AppColors.warning,
        background: AppColors.warningContainer,
      ),
      SyncStatus.failed => (
        label: 'Lỗi',
        icon: Icons.error,
        foreground: AppColors.error,
        background: AppColors.errorContainer,
      ),
    };

    final chip = Container(
      constraints: BoxConstraints(
        minHeight: onTap == null ? 32 : AppSpacing.minTapTarget,
        minWidth: onTap == null ? 0 : AppSpacing.minTapTarget,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: visual.foreground),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 20, color: visual.foreground),
          const SizedBox(width: 8),
          Text(
            visual.label,
            style: AppTypography.labelLarge.copyWith(color: visual.foreground),
          ),
        ],
      ),
    );

    return Semantics(
      label: visual.label,
      button: onTap != null,
      child: onTap == null
          ? chip
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                child: chip,
              ),
            ),
    );
  }
}
