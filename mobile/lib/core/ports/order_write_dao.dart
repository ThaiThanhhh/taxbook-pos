/// Hợp đồng ghi đơn bán xuống DB trên máy. Dart thuần: không Flutter, không
/// drift, không mạng.
///
/// Schema orders đóng băng cho Dev 2 từ F08. Quy ước các cột:
/// - Tiền là `int` VND.
/// - `created_at` là chuỗi ISO-8601 UTC, đuôi `Z`.
/// - `orders.discount_vnd` là tổng tiền giảm của cả đơn, gồm cả giảm từng
///   dòng. Luôn có: total_vnd = Σ(unit_price_vnd × quantity) − discount_vnd.
/// - `order_items.line_discount_vnd` là phần giảm của riêng dòng đó (đã nằm
///   trong `orders.discount_vnd`, không cộng thêm lần nữa).
/// - Đơn đã ghi không UPDATE.
library;

/// Một hàng `orders` sắp ghi.
final class NewOrder {
  const NewOrder({
    required this.id,
    required this.idempotencyKey,
    required this.tempNumber,
    required this.paymentMethod,
    required this.discountVnd,
    required this.totalVnd,
    required this.createdAtUtc,
    required this.devicePrefix,
  });

  final String id;
  final String idempotencyKey;
  final String tempNumber;

  /// Giá trị DB của phương thức trả tiền (`cash` | `bank_qr`).
  final String paymentMethod;
  final int discountVnd;
  final int totalVnd;
  final String createdAtUtc;
  final String devicePrefix;
}

/// Một hàng `order_items` sắp ghi; tên và giá chụp lại lúc bán.
final class NewOrderItem {
  const NewOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.nameSnapshot,
    required this.unitPriceVnd,
    required this.quantity,
    required this.lineDiscountVnd,
    required this.lineTotalVnd,
  });

  final String id;
  final String orderId;
  final String productId;
  final String nameSnapshot;
  final int unitPriceVnd;
  final int quantity;
  final int lineDiscountVnd;
  final int lineTotalVnd;
}

/// Một mục outbox mới. Bản cài đặt luôn ghi trạng thái `pending`.
final class NewOutboxEntry {
  const NewOutboxEntry({
    required this.idempotencyKey,
    required this.payloadJson,
    required this.createdAtUtc,
  });

  final String idempotencyKey;
  final String payloadJson;
  final String createdAtUtc;
}

/// Các thao tác ghi mà SaveOrder cần. Mọi hàm trừ [transaction] chỉ được
/// gọi bên trong [transaction].
abstract interface class OrderWriteDao {
  /// Chạy [action] trong một transaction DB. [action] ném lỗi thì mọi thứ
  /// đã ghi trong đó được hoàn lại, rồi lỗi được ném tiếp.
  Future<T> transaction<T>(Future<T> Function() action);

  /// Tăng bộ đếm của ([devicePrefix], [dayKey]) rồi trả số mới. Đơn đầu ngày
  /// nhận 1. Không đụng tới bộ đếm của ngày khác.
  Future<int> nextDaySeq({
    required String devicePrefix,
    required String dayKey,
  });

  Future<void> insertOrder(NewOrder order);

  Future<void> insertOrderItem(NewOrderItem item);

  Future<void> insertOutbox(NewOutboxEntry entry);
}
