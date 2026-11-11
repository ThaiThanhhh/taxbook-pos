import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/app_text_field.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:dt13_pos/features/onboarding/data/onboarding_providers.dart';
import 'package:dt13_pos/features/onboarding/domain/business_profile.dart';
import 'package:dt13_pos/features/tax/domain/tax_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _taxCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  TaxSector _primarySector = TaxSector.GOODS_DISTRIBUTION;
  String _taxMethod = 'PERCENTAGE_OVER_THRESHOLD';
  String? _businessNameError;
  String? _taxCodeError;
  String? _saveError;
  bool _isSaving = false;

  static const Map<TaxSector, String> _sectorLabels = {
    TaxSector.GOODS_DISTRIBUTION: 'Phân phối hàng hóa',
    TaxSector.SERVICE: 'Dịch vụ',
    TaxSector.PRODUCTION_TRANSPORT: 'Sản xuất / Vận tải',
    TaxSector.OTHER: 'Khác',
  };

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khai báo hộ kinh doanh')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bắt đầu sử dụng ĐT13 POS',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Thông tin này giúp ứng dụng ghi nhận hoạt động và ước tính thuế phù hợp.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _businessNameController,
                label: 'Tên Hộ kinh doanh / Cửa hàng *',
                hint: 'Nhập tên cửa hàng',
                errorText: _businessNameError,
                onChanged: (_) {
                  if (_businessNameError != null || _saveError != null) {
                    setState(() {
                      _businessNameError = null;
                      _saveError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _taxCodeController,
                label: 'Mã số thuế *',
                hint: 'Nhập 10 hoặc 13 chữ số',
                kind: AppTextFieldKind.taxCode,
                errorText: _taxCodeError,
                onChanged: (_) {
                  if (_taxCodeError != null || _saveError != null) {
                    setState(() {
                      _taxCodeError = null;
                      _saveError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Địa chỉ kinh doanh (không bắt buộc)',
                hint: 'Nhập địa chỉ cửa hàng',
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhóm ngành nghề kinh doanh chính',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaxSector>(
                initialValue: _primarySector,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.padding,
                    vertical: 16,
                  ),
                ),
                items: TaxSector.values
                    .map(
                      (sector) => DropdownMenuItem(
                        value: sector,
                        child: Text(_sectorLabels[sector]!),
                      ),
                    )
                    .toList(),
                onChanged: (sector) {
                  if (sector != null) {
                    setState(() => _primarySector = sector);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Phương pháp tính thuế',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: RadioGroup<String>(
                  groupValue: _taxMethod,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _taxMethod = value);
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        value: 'PERCENTAGE_OVER_THRESHOLD',
                        title: Text('Tỷ lệ phần vượt'),
                      ),
                      RadioListTile<String>(
                        value: 'PROFIT_BASED',
                        title: Text('Theo lợi nhuận'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _saveError!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Hoàn tất & Bắt đầu sử dụng',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final businessName = _businessNameController.text.trim();
    final taxCode = _taxCodeController.text.trim();
    final hasValidName = businessName.isNotEmpty;
    final hasValidTaxCode = RegExp(r'^(?:\d{10}|\d{13})$').hasMatch(taxCode);

    setState(() {
      _businessNameError = hasValidName
          ? null
          : 'Vui lòng nhập tên hộ kinh doanh.';
      _taxCodeError = hasValidTaxCode
          ? null
          : 'Mã số thuế phải gồm đúng 10 hoặc 13 chữ số.';
      _saveError = null;
    });
    if (!hasValidName || !hasValidTaxCode) return;

    final profile = BusinessProfile(
      taxCode: taxCode,
      businessName: businessName,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      primarySector: _primarySector,
      taxMethod: _taxMethod,
    );

    setState(() => _isSaving = true);
    try {
      await ref
          .read(businessProfileNotifierProvider.notifier)
          .saveBusinessProfile(profile);
      await ref.read(onboardingRepositoryProvider).setOnboardingCompleted(true);
      if (mounted) context.go(AppRoutes.sales);
    } on Exception {
      if (mounted) {
        setState(() {
          _saveError = 'Không thể lưu thông tin lúc này. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
