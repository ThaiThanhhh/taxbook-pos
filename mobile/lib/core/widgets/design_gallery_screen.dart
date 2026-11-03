import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_button.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/app_text_field.dart';
import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/core/widgets/outline_button.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:dt13_pos/core/widgets/secondary_button.dart';
import 'package:dt13_pos/core/widgets/status_chip.dart';
import 'package:flutter/material.dart';

/// Liệt kê token và mọi trạng thái widget. Chỉ gắn route khi kDebugMode.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thư viện giao diện')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.padding),
        children: const [
          _Note(
            'Chỉ có trong bản debug. Màu inputBorder #667085 và nhãn nút 16 '
            'là đề xuất, chưa chốt với nhóm.',
          ),
          SizedBox(height: 16),
          _Section(title: 'Màu', child: _ColorBoard()),
          _Section(title: 'Chữ', child: _TypeBoard()),
          _Section(title: 'Nút', child: _ButtonBoard()),
          _Section(title: 'Ô nhập', child: _FieldBoard()),
          _Section(title: 'Tiền', child: _MoneyBoard()),
          _Section(title: 'Trạng thái đồng bộ', child: _ChipBoard()),
          _Section(title: 'Thẻ', child: _CardBoard()),
          _Section(title: 'Rỗng / lỗi', child: _StateBoard()),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.bodyMedium);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ColorBoard extends StatelessWidget {
  const _ColorBoard();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Swatch(name: 'Primary', hex: '#145C4B', color: AppColors.primary),
        _Swatch(name: 'Success', hex: '#1F7A4D', color: AppColors.success),
        _Swatch(name: 'Error', hex: '#B42318', color: AppColors.error),
        _Swatch(name: 'Warning', hex: '#B54708', color: AppColors.warning),
        _Swatch(name: 'Nền', hex: '#F7F9F8', color: AppColors.background),
        _Swatch(name: 'Surface', hex: '#FFFFFF', color: AppColors.surface),
        _Swatch(name: 'Chữ', hex: '#1D2939', color: AppColors.textPrimary),
        _Swatch(name: 'Viền nhẹ', hex: '#D0D5DD', color: AppColors.border),
        _Swatch(
          name: 'Viền ô nhập',
          hex: '#667085',
          color: AppColors.inputBorder,
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.hex, required this.color});

  final String name;
  final String hex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: AppTypography.labelLarge),
          Text(hex, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

class _TypeBoard extends StatelessWidget {
  const _TypeBoard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Headline 28', style: AppTypography.headlineLarge),
        Text('Headline 24', style: AppTypography.headlineSmall),
        Text('Title 20', style: AppTypography.titleMedium),
        Text('Title 18', style: AppTypography.titleSmall),
        Text('Body 16 — nội dung màn bán hàng', style: AppTypography.bodyLarge),
        Text('Body 14', style: AppTypography.bodyMedium),
        Text('Label 14', style: AppTypography.labelLarge),
        Text(
          'Label 12 — không dùng trên màn bán hàng',
          style: AppTypography.labelSmall,
        ),
      ],
    );
  }
}

class _ButtonBoard extends StatelessWidget {
  const _ButtonBoard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(label: 'Lưu đơn', onPressed: _noop),
        SizedBox(height: 12),
        PrimaryButton(
          label: 'Thanh toán',
          size: AppButtonSize.large,
          onPressed: _noop,
        ),
        SizedBox(height: 12),
        PrimaryButton(label: 'Đang gửi', isLoading: true, onPressed: _noop),
        SizedBox(height: 12),
        PrimaryButton(label: 'Không bấm được', onPressed: null),
        SizedBox(height: 12),
        SecondaryButton(label: 'Nút phụ', onPressed: _noop),
        SizedBox(height: 12),
        SecondaryButton(label: 'Đang tải', isLoading: true, onPressed: _noop),
        SizedBox(height: 12),
        SecondaryButton(label: 'Tắt', onPressed: null),
        SizedBox(height: 12),
        OutlineButton(label: 'Nút viền', onPressed: _noop),
        SizedBox(height: 12),
        OutlineButton(label: 'Đang tải', isLoading: true, onPressed: _noop),
        SizedBox(height: 12),
        OutlineButton(label: 'Tắt', onPressed: null),
      ],
    );
  }
}

class _FieldBoard extends StatelessWidget {
  const _FieldBoard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTextField(label: 'Tên khách', hint: 'Nguyễn Văn A'),
        SizedBox(height: 16),
        AppTextField(label: 'Số tiền', kind: AppTextFieldKind.money),
        SizedBox(height: 16),
        AppTextField(
          label: 'Mã số thuế',
          hint: 'Chỉ chữ số',
          kind: AppTextFieldKind.taxCode,
        ),
        SizedBox(height: 16),
        AppTextField(label: 'Ô lỗi', errorText: 'Nhập số tiền lớn hơn 0'),
        SizedBox(height: 16),
        AppTextField(label: 'Đã khóa', enabled: false, hint: 'Không sửa'),
      ],
    );
  }
}

class _MoneyBoard extends StatelessWidget {
  const _MoneyBoard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        children: [
          MoneyText(1250000),
          SizedBox(height: 8),
          MoneyText(0),
          SizedBox(height: 8),
          MoneyText(-1250000),
        ],
      ),
    );
  }
}

class _ChipBoard extends StatelessWidget {
  const _ChipBoard();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        StatusChip(SyncStatus.synced),
        StatusChip(SyncStatus.pending),
        StatusChip(SyncStatus.failed),
      ],
    );
  }
}

class _CardBoard extends StatelessWidget {
  const _CardBoard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Text(
        'Thẻ nền trắng, viền nhẹ, radius 8.',
        style: AppTypography.bodyLarge,
      ),
    );
  }
}

class _StateBoard extends StatelessWidget {
  const _StateBoard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(
          height: 220,
          child: EmptyState(
            title: 'Chưa có đơn hàng',
            message: 'Đơn bán trong ngày sẽ hiện ở đây.',
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ErrorState(
            message: 'Không kết nối được. Dữ liệu vẫn nằm trên máy.',
            onRetry: _noop,
          ),
        ),
      ],
    );
  }
}

void _noop() {}
