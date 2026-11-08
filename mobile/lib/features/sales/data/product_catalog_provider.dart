import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/db/app_database_provider.dart';
import 'package:dt13_pos/core/utils/system_clock.dart';
import 'package:dt13_pos/features/sales/data/product_repository.dart';
import 'package:dt13_pos/features/sales/domain/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_catalog_provider.g.dart';

/// Danh mục món cho màn bán. Bản dev/staging tự nạp 24 món mẫu khi bảng
/// `products` còn trống; prod không nạp (hiện "Chưa có món").
///
/// Test widget override provider này bằng một [ProductCatalog] giả.
@Riverpod(keepAlive: true)
ProductCatalog productCatalog(Ref ref) {
  final repository = ProductRepository(
    database: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  );
  return SeedIfEmptyCatalog(
    repository,
    seedIfEmpty: !ref.watch(appEnvProvider).isProd,
  );
}

/// Đọc món từ [ProductRepository]; nếu được phép và bảng trống thì nạp món
/// mẫu trước. Seed là upsert theo id nên gọi lại (bấm Thử lại) vẫn an toàn.
final class SeedIfEmptyCatalog implements ProductCatalog {
  SeedIfEmptyCatalog(this._repository, {required this.seedIfEmpty});

  final ProductRepository _repository;
  final bool seedIfEmpty;

  @override
  Future<List<Product>> listForSale() async {
    if (seedIfEmpty && !await _repository.hasAnyProduct()) {
      await _repository.seedFromAsset();
    }
    return _repository.listForSale();
  }
}
