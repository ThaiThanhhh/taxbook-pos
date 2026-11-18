/// Nguồn id mới cho đơn, dòng đơn và Idempotency-Key. Dart thuần.
///
/// Implementation trong app: `UuidV7IdGenerator` (core/utils), trả UUID v7
/// dạng chuỗi thường 36 ký tự, ký tự thứ 15 (version) là '7'.
abstract interface class IdGenerator {
  String newId();
}
