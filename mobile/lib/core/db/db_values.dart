/// Giá trị hợp lệ cho các cột "enum dạng TEXT" trong DB local.
///
/// Dart thuần (không import Flutter/drift) để test được bằng `dart test`.
/// Đây là nguồn duy nhất của tập giá trị: tầng ghi ([requireValidOutboxState],
/// [requireValidPaymentMethod]) và CHECK constraint trong `tables.dart` đều
/// đọc từ [OutboxState.dbValues] / [PaymentMethod.dbValues].
library;

/// Trạng thái một mục outbox.
enum OutboxState {
  pending('pending'),
  sending('sending'),
  done('done'),
  failedRetryable('failed_retryable'),
  failedPermanent('failed_permanent');

  const OutboxState(this.dbValue);

  static const column = 'outbox.state';

  /// Chuỗi lưu trong cột `outbox.state`.
  final String dbValue;

  static final List<String> dbValues = List.unmodifiable(
    values.map((s) => s.dbValue),
  );

  /// Đọc từ DB; giá trị lạ ném [InvalidDbValueException].
  static OutboxState fromDb(String raw) => values.firstWhere(
    (s) => s.dbValue == raw,
    orElse: () => throw InvalidDbValueException(column: column, value: raw),
  );
}

/// Phương thức thanh toán. `null` ở DB nghĩa là chưa chọn.
enum PaymentMethod {
  cash('cash'),
  bankQr('bank_qr');

  const PaymentMethod(this.dbValue);

  static const column = 'orders.payment_method';

  /// Chuỗi lưu trong cột `orders.payment_method`.
  final String dbValue;

  static final List<String> dbValues = List.unmodifiable(
    values.map((m) => m.dbValue),
  );

  /// Đọc từ DB; `null` giữ nguyên, giá trị lạ ném [InvalidDbValueException].
  static PaymentMethod? fromDb(String? raw) => raw == null
      ? null
      : values.firstWhere(
          (m) => m.dbValue == raw,
          orElse: () =>
              throw InvalidDbValueException(column: column, value: raw),
        );
}

/// Ném khi tầng ghi nhận giá trị không nằm trong tập cho phép.
///
/// Dùng exception thay vì `assert` vì assert bị tắt ở bản release.
class InvalidDbValueException implements Exception {
  const InvalidDbValueException({required this.column, required this.value});

  final String column;
  final Object? value;

  @override
  String toString() =>
      'InvalidDbValueException: giá trị "$value" không hợp lệ cho $column';
}

/// Chặn `outbox.state` ngoài 5 giá trị cho phép trước khi ghi.
void requireValidOutboxState(String value) => OutboxState.fromDb(value);

/// Chặn `orders.payment_method` ngoài `cash | bank_qr | null` trước khi ghi.
void requireValidPaymentMethod(String? value) => PaymentMethod.fromDb(value);
