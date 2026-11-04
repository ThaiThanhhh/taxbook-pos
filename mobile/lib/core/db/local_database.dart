import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_database.g.dart';

/// Hợp đồng lớp lưu trữ cục bộ (offline-first: mọi giao dịch ghi vào DB
/// trên máy trước, sync lên server sau).
///
/// TODO(gia-bao): thay [NoopLocalDatabase] bằng implementation SQLite
/// (drift hoặc sqflite) sau khi chốt schema + migration với backend.
abstract interface class LocalDatabase {
  Future<void> open();
  Future<void> close();
}

class NoopLocalDatabase implements LocalDatabase {
  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {}
}

@Riverpod(keepAlive: true)
LocalDatabase localDatabase(Ref ref) {
  final db = NoopLocalDatabase();
  ref.onDispose(() => unawaited(db.close()));
  return db;
}
