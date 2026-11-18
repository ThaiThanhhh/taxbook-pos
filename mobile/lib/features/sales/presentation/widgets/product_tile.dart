import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:flutter/material.dart';

/// Ô món trên lưới bán: tên (16) và giá. Cả ô là vùng bấm, tối thiểu 48.
class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onTap, super.key});

  /// Số dòng tối đa của tên món.
  static const int nameMaxLines = 2;

  /// Chiều cao ô theo cỡ chữ hệ thống, để chữ phóng to không bị tràn.
  static double heightFor(TextScaler scaler) {
    final nameHeight =
        scaler.scale(AppTypography.bodyLarge.fontSize!) *
        AppTypography.bodyLarge.height! *
        nameMaxLines;
    final priceHeight =
        scaler.scale(AppTypography.money.fontSize!) *
        AppTypography.money.height!;
    const gap = 8;
    const slack = 4;
    return AppSpacing.padding * 2 + nameHeight + gap + priceHeight + slack;
  }

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Tên và giá bên trong đã được đọc; chỉ báo thêm đây là nút.
    return Semantics(
      button: true,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.name,
              style: AppTypography.bodyLarge,
              maxLines: nameMaxLines,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Ô hẹp + chữ hệ thống lớn: giá co lại cho vừa một dòng, không
            // xuống dòng làm tràn ô.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: MoneyText(product.unitPriceVnd),
            ),
          ],
        ),
      ),
    );
  }
}
