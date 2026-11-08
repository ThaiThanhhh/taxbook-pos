import 'package:dt13_pos/core/db/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_database.g.dart';

/// Hợp đồng lớp lưu trữ cục bộ (offline-first: mọi giao dịch ghi vào DB
/// trên máy trước, sync lên server sau).
///
/// Implementation SQLite: `AppDatabase` (app_database.dart).
abstract interface class LocalDatabase {
  Future<void> open();
  Future<void> close();
}

/// DB không làm gì; giữ cho test cần một [LocalDatabase] rỗng.
class NoopLocalDatabase implements LocalDatabase {
  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {}
}

/// Cùng một `AppDatabase` với [appDatabaseProvider]. Việc đóng DB do
/// [appDatabaseProvider] lo, ở đây không đăng ký onDispose lần hai.
@Riverpod(keepAlive: true)
LocalDatabase localDatabase(Ref ref) => ref.watch(appDatabaseProvider);
