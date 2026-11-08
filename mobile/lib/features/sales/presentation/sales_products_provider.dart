import 'package:dt13_pos/core/utils/app_logger.dart';
import 'package:dt13_pos/features/sales/data/product_catalog_provider.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sales_products_provider.g.dart';

/// Tắt retry tự động của Riverpod: chỉ đọc lại khi người dùng bấm Thử lại,
/// để màn lỗi đứng yên và không gọi DB liên tục.
Duration? _noAutoRetry(int retryCount, Object error) => null;

/// Món hiện trên lưới bán. Lỗi chỉ log ở debug (không kèm dữ liệu người
/// dùng), rồi ném tiếp để màn hình hiện ErrorState.
@Riverpod(retry: _noAutoRetry)
Future<List<Product>> salesProducts(Ref ref) async {
  try {
    return await ref.watch(productCatalogProvider).listForSale();
  } catch (error, stackTrace) {
    AppLogger.e(
      'Không đọc được danh sách món',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
