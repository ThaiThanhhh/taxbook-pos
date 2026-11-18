/// F08 – lưu đơn bán. Dart thuần: không Flutter, không drift, không mạng.
///
/// Một lần gọi = một transaction DB ghi: bộ đếm số phiếu, `orders`,
/// `order_items`, `outbox`. Mọi thứ cần await ngoài DB (đọc giờ, sinh UUID,
/// tính tiền, dựng payload) làm xong TRƯỚC khi mở transaction.
///
/// Đơn đã ghi không UPDATE. Hoàn trả chưa làm.
library;

import 'dart:convert';

import 'package:dt13_pos/core/db/db_values.dart';
import 'package:dt13_pos/core/ports/clock.dart';
import 'package:dt13_pos/core/ports/id_generator.dart';
import 'package:dt13_pos/core/ports/order_write_dao.dart';
import 'package:dt13_pos/core/utils/vn_time.dart';
import 'package:dt13_pos/features/sales/domain/cart_calc.dart';

/// Kết quả lưu một đơn.
final class SavedOrder {
  const SavedOrder({
    required this.orderId,
    required this.idempotencyKey,
    required this.tempNumber,
    required this.totalVnd,
    required this.payloadJson,
  });

  final String orderId;

  /// UUID v7, sinh một lần lúc tạo đơn; outbox gửi lại vẫn dùng đúng key này.
  final String idempotencyKey;

  /// `<device_prefix>-<yyMMdd>-<seq 4 số>`, ví dụ `A1-261113-0001`.
  final String tempNumber;
  final int totalVnd;

  /// Đúng chuỗi đã ghi vào `outbox.payload_json`.
  final String payloadJson;
}

/// Lưu giỏ thành đơn.
///
/// Gọi chồng: khi một lần lưu đang chạy, lần gọi tiếp theo nhận lại đúng kết
/// quả của lần đang chạy và KHÔNG mở transaction thứ hai.
final class SaveOrder {
  SaveOrder({
    required this._dao,
    required this._clock,
    required this._ids,
    required this._devicePrefix,
  });

  final OrderWriteDao _dao;
  final Clock _clock;
  final IdGenerator _ids;
  final String _devicePrefix;

  Future<SavedOrder>? _inFlight;

  /// Lưu [lines] với giảm cả đơn [orderDiscountBp] (basis point).
  ///
  /// Ném [CartError] khi giỏ sai (rỗng, số lượng, giá, tỷ lệ). Lỗi DB được
  /// ném nguyên; khi đó không có gì được ghi (transaction hoàn lại).
  Future<SavedOrder> call(
    List<CartLine> lines, {
    required int orderDiscountBp,
    required PaymentMethod paymentMethod,
  }) {
    final running = _inFlight;
    if (running != null) {
      return running;
    }
    final attempt = _save(
      lines,
      orderDiscountBp: orderDiscountBp,
      paymentMethod: paymentMethod,
    );
    _inFlight = attempt;
    return attempt.whenComplete(() => _inFlight = null);
  }

  Future<SavedOrder> _save(
    List<CartLine> lines, {
    required int orderDiscountBp,
    required PaymentMethod paymentMethod,
  }) async {
    // --- Trước transaction: không chạm DB. ---
    final totals = calcCart(lines, orderDiscountBp: orderDiscountBp);
    final nowUtc = _clock.nowUtc().toUtc();
    final createdAt = nowUtc.toIso8601String();
    final dayKey = vnDayKey(nowUtc);

    // Idempotency-Key: sinh đúng một lần ở đây, không sinh lại ở đâu khác.
    final idempotencyKey = _ids.newId();
    final orderId = _ids.newId();
    final itemIds = [for (final _ in lines) _ids.newId()];

    // Giảm cả đơn gồm giảm từng dòng; total = Σ(giá × SL) − discount.
    final discountVnd = totals.lineDiscountVnd + totals.orderDiscountVnd;

    final items = <NewOrderItem>[
      for (var i = 0; i < lines.length; i++)
        _itemOf(itemIds[i], orderId, lines[i]),
    ];

    // --- Một transaction duy nhất; bên trong chỉ có lệnh DB. ---
    final written = await _dao.transaction(() async {
      final seq = await _dao.nextDaySeq(
        devicePrefix: _devicePrefix,
        dayKey: dayKey,
      );
      final number = _tempNumber(_devicePrefix, dayKey, seq);
      final payload = _payloadJson(
        tempNumber: number,
        lines: lines,
        discountVnd: discountVnd,
        paymentMethod: paymentMethod,
        createdAt: createdAt,
      );
      await _dao.insertOrder(
        NewOrder(
          id: orderId,
          idempotencyKey: idempotencyKey,
          tempNumber: number,
          paymentMethod: paymentMethod.dbValue,
          discountVnd: discountVnd,
          totalVnd: totals.totalVnd,
          createdAtUtc: createdAt,
          devicePrefix: _devicePrefix,
        ),
      );
      for (final item in items) {
        await _dao.insertOrderItem(item);
      }
      await _dao.insertOutbox(
        NewOutboxEntry(
          idempotencyKey: idempotencyKey,
          payloadJson: payload,
          createdAtUtc: createdAt,
        ),
      );
      return (number: number, payload: payload);
    });

    return SavedOrder(
      orderId: orderId,
      idempotencyKey: idempotencyKey,
      tempNumber: written.number,
      totalVnd: totals.totalVnd,
      payloadJson: written.payload,
    );
  }
}

/// Dòng đơn: tên và đơn giá lấy từ dòng giỏ đã chụp, không đọc lại `products`.
NewOrderItem _itemOf(String id, String orderId, CartLine line) {
  final grossVnd = line.unitPriceVnd * line.quantity;
  return NewOrderItem(
    id: id,
    orderId: orderId,
    productId: line.productId,
    nameSnapshot: line.name,
    unitPriceVnd: line.unitPriceVnd,
    quantity: line.quantity,
    lineDiscountVnd: grossVnd - lineNetVnd(line),
    lineTotalVnd: lineNetVnd(line),
  );
}

String _tempNumber(String devicePrefix, String dayKey, int seq) =>
    '$devicePrefix-$dayKey-${seq.toString().padLeft(4, '0')}';

/// Khớp OrderCreate: temp_number, items[{product_id, quantity,
/// unit_price_vnd}], discount_vnd, payment_method, created_at (UTC).
String _payloadJson({
  required String tempNumber,
  required List<CartLine> lines,
  required int discountVnd,
  required PaymentMethod paymentMethod,
  required String createdAt,
}) => jsonEncode(<String, Object>{
  'temp_number': tempNumber,
  'items': [
    for (final line in lines)
      <String, Object>{
        'product_id': line.productId,
        'quantity': line.quantity,
        'unit_price_vnd': line.unitPriceVnd,
      },
  ],
  'discount_vnd': discountVnd,
  'payment_method': paymentMethod.dbValue,
  'created_at': createdAt,
});
