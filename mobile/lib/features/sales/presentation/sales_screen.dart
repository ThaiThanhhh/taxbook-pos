import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/empty_state.dart';
import 'package:dt13_pos/core/widgets/error_state.dart';
import 'package:dt13_pos/features/sales/domain/cart_calc.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:dt13_pos/features/sales/presentation/cart_notifier.dart';
import 'package:dt13_pos/features/sales/presentation/sales_products_provider.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/cart_bar.dart';
import 'package:dt13_pos/features/sales/presentation/widgets/product_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Màn bán hàng (F06): lưới món đọc từ DB và thanh giỏ ở đáy.
///
/// Bốn trạng thái: đang tải (vòng tròn), lỗi (Thử lại), 0 món, có món.
/// Banner trên cùng luôn hiện, kể cả khi đang tải hoặc lỗi.
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  static const String title = 'Bán hàng';
  static const String bannerText = 'Đang bán trên máy';
  static const String emptyTitle = 'Chưa có món';
  static const String errorMessage = 'Không đọc được danh sách món trên máy.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(salesProductsProvider);

    // Bấm Thử lại thì hiện lại vòng tròn, không giữ màn lỗi cũ.
    final body = products.when(
      skipLoadingOnRefresh: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ErrorState(
        message: errorMessage,
        onRetry: () => ref.invalidate(salesProductsProvider),
      ),
      data: (value) => value.isEmpty
          ? const EmptyState(title: emptyTitle, icon: Icons.restaurant_menu)
          : _ProductGrid(products: value),
    );

    final hasProducts =
        !products.isLoading && (products.value?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        actions: [
          IconButton(
            tooltip: 'Đơn đã bán',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.go(AppRoutes.history),
          ),
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OfflineBanner(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: hasProducts ? const CartBar() : null,
    );
  }
}

/// Banner chế độ bán. Chữ cố định hôm nay; số đơn chờ gửi chưa có nguồn thật
/// nên không hiện con số nào.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.padding,
          vertical: 8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.phone_android,
              color: AppColors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                SalesScreen.bannerText,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileHeight = ProductTile.heightFor(MediaQuery.textScalerOf(context));
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.padding),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: tileHeight,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductTile(
          key: ValueKey(product.id),
          product: product,
          onTap: () => ref
              .read(cartProvider.notifier)
              .add(
                CartLine(
                  productId: product.id,
                  name: product.name,
                  unitPriceVnd: product.unitPriceVnd,
                  quantity: 1,
                ),
              ),
        );
      },
    );
  }
}
