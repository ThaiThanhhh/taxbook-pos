import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:dt13_pos/core/db/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database_provider.g.dart';

/// Tên file SQLite trong thư mục dữ liệu riêng của app (không phải bộ nhớ
/// chung, không cần quyền đọc/ghi thẻ nhớ).
const String kAppDatabaseFileName = 'dt13_pos.sqlite';

/// Một kết nối DB cho cả app. File chỉ được mở ở truy vấn đầu tiên
/// ([LazyDatabase]); SQLite chạy trên isolate nền để không giật UI.
///
/// Test override bằng `AppDatabase(NativeDatabase.memory())`.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}$kAppDatabaseFileName',
      );
      return NativeDatabase.createInBackground(file);
    }),
  );
  ref.onDispose(() => unawaited(db.close()));
  return db;
}
