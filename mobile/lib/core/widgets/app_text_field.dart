import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:dt13_pos/core/widgets/vnd_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppTextFieldKind { text, money, taxCode }

/// Ô nhập cao khoảng 56, padding ngang 16.
///
/// Nhãn đặt phía trên (không thu nhỏ khi focus) để người lớn tuổi đọc được.
/// [AppTextFieldKind.money]: bàn phím số, tự thêm dấu chấm, [onMoneyChanged]
/// trả int (rỗng → null). [AppTextFieldKind.taxCode]: chỉ cho nhập chữ số.
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.kind = AppTextFieldKind.text,
    this.keyboardType,
    this.onChanged,
    this.onMoneyChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final AppTextFieldKind kind;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<int?>? onMoneyChanged;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  String _lastNotified = '';

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _rewriteIfNeeded();
    _lastNotified = _controller.text;
    _controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMoney = widget.kind == AppTextFieldKind.money;
    final digitsOnly = isMoney || widget.kind == AppTextFieldKind.taxCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          keyboardType: digitsOnly
              ? TextInputType.number
              : widget.keyboardType ?? TextInputType.text,
          style: AppTypography.bodyLarge.copyWith(
            color: widget.enabled
                ? AppColors.textPrimary
                : AppColors.onDisabled,
            fontFeatures: isMoney ? const [FontFeature.tabularFigures()] : null,
          ),
          inputFormatters: [
            if (isMoney) const VndInputFormatter(),
            if (widget.kind == AppTextFieldKind.taxCode)
              FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: widget.hint ?? (isMoney ? '0' : null),
            errorText: widget.errorText,
            suffixText: isMoney ? MoneyFormat.symbol : null,
            suffixStyle: AppTypography.bodyLarge,
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : AppColors.disabledBackground,
            constraints: const BoxConstraints(
              minHeight: AppSpacing.fieldHeight,
            ),
          ),
        ),
      ],
    );
  }

  void _handleChange() {
    if (_rewriteIfNeeded()) return;
    final text = _controller.text;
    if (text == _lastNotified) return;
    _lastNotified = text;
    widget.onChanged?.call(text);
    if (widget.kind == AppTextFieldKind.money) {
      widget.onMoneyChanged?.call(MoneyFormat.parseDigits(text));
    }
  }

  /// Trả true nếu đã ghi lại chuỗi (listener sẽ chạy lại).
  bool _rewriteIfNeeded() {
    final next = _displayText(_controller.text);
    if (next == _controller.text) return false;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    return true;
  }

  String _displayText(String raw) {
    switch (widget.kind) {
      case AppTextFieldKind.money:
        final parsed = MoneyFormat.parseDigits(raw);
        if (parsed == null) return '';
        return MoneyFormat.group(parsed);
      case AppTextFieldKind.taxCode:
        return raw.replaceAll(RegExp('[^0-9]'), '');
      case AppTextFieldKind.text:
        return raw;
    }
  }
}
