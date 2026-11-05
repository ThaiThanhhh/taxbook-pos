/// F02 – tính tiền giỏ hàng. Dart thuần: không Flutter, không DB, không mạng.
///
/// Tiền là `int` VND, tỷ lệ là basis point (1% = 100, 100% = 10000).
/// Mọi phép chia dùng `~/` (cắt phần dư, không làm tròn nửa lên).
library;

/// Basis point tương ứng 100%.
const int kBasisPointMax = 10000;

/// Lỗi dữ liệu giỏ hàng. `calcCart` ném lỗi thay vì trả tổng 0.
enum CartError implements Exception {
  /// Giỏ không có dòng nào.
  empty,

  /// Số lượng nhỏ hơn 1.
  quantity,

  /// Đơn giá nhỏ hơn 1 đồng.
  price,

  /// Tỷ lệ giảm giá (dòng hoặc đơn) ngoài 0..10000.
  rate,

  /// Giảm giá làm tổng tiền âm.
  negative,
}

/// Một dòng trong giỏ. Hai dòng cùng [productId] được giữ riêng, không gộp.
final class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unitPriceVnd,
    required this.quantity,
    this.lineDiscountBp = 0,
  });

  final String productId;
  final String name;
  final int unitPriceVnd;
  final int quantity;
  final int lineDiscountBp;

  @override
  bool operator ==(Object other) =>
      other is CartLine &&
      other.productId == productId &&
      other.name == name &&
      other.unitPriceVnd == unitPriceVnd &&
      other.quantity == quantity &&
      other.lineDiscountBp == lineDiscountBp;

  @override
  int get hashCode =>
      Object.hash(productId, name, unitPriceVnd, quantity, lineDiscountBp);

  @override
  String toString() =>
      'CartLine($productId, $name, $unitPriceVnd x $quantity, '
      '-${lineDiscountBp}bp)';
}

/// Kết quả tính tiền.
///
/// - [subtotalVnd]: tổng đơn giá × số lượng, chưa trừ giảm giá.
/// - [lineDiscountVnd]: tổng tiền giảm theo từng dòng.
/// - [orderDiscountVnd]: tiền giảm trên cả đơn, tính sau giảm dòng.
/// - [totalVnd] = subtotal − lineDiscount − orderDiscount.
final class CartTotals {
  const CartTotals({
    required this.subtotalVnd,
    required this.lineDiscountVnd,
    required this.orderDiscountVnd,
    required this.totalVnd,
  });

  final int subtotalVnd;
  final int lineDiscountVnd;
  final int orderDiscountVnd;
  final int totalVnd;

  @override
  bool operator ==(Object other) =>
      other is CartTotals &&
      other.subtotalVnd == subtotalVnd &&
      other.lineDiscountVnd == lineDiscountVnd &&
      other.orderDiscountVnd == orderDiscountVnd &&
      other.totalVnd == totalVnd;

  @override
  int get hashCode =>
      Object.hash(subtotalVnd, lineDiscountVnd, orderDiscountVnd, totalVnd);

  @override
  String toString() =>
      'CartTotals(subtotal: $subtotalVnd, lineDiscount: $lineDiscountVnd, '
      'orderDiscount: $orderDiscountVnd, total: $totalVnd)';
}

/// Tính tổng giỏ hàng. Đây là nơi duy nhất giữ quy tắc tính tiền.
///
/// - Thành tiền dòng = giá × SL − (giá × SL × lineDiscountBp ~/ 10000)
/// - Giảm giá đơn = tổng sau giảm dòng × orderDiscountBp ~/ 10000
///
/// Ném [CartError] khi dữ liệu sai; không kẹp tổng âm về 0.
CartTotals calcCart(List<CartLine> lines, {required int orderDiscountBp}) {
  if (lines.isEmpty) {
    throw CartError.empty;
  }
  _checkRate(orderDiscountBp);

  var subtotalVnd = 0;
  var lineDiscountVnd = 0;
  for (final line in lines) {
    if (line.quantity < 1) {
      throw CartError.quantity;
    }
    if (line.unitPriceVnd < 1) {
      throw CartError.price;
    }
    _checkRate(line.lineDiscountBp);

    final grossVnd = line.unitPriceVnd * line.quantity;
    subtotalVnd += grossVnd;
    lineDiscountVnd += grossVnd * line.lineDiscountBp ~/ kBasisPointMax;
  }

  final afterLineDiscountVnd = subtotalVnd - lineDiscountVnd;
  final orderDiscountVnd =
      afterLineDiscountVnd * orderDiscountBp ~/ kBasisPointMax;
  final totalVnd = afterLineDiscountVnd - orderDiscountVnd;

  // Với tỷ lệ đã chặn 0..10000 thì không thể âm; giữ kiểm tra phòng khi
  // quy tắc giảm giá thay đổi về sau (ví dụ giảm theo số tiền cố định).
  if (afterLineDiscountVnd < 0 || totalVnd < 0) {
    throw CartError.negative;
  }

  return CartTotals(
    subtotalVnd: subtotalVnd,
    lineDiscountVnd: lineDiscountVnd,
    orderDiscountVnd: orderDiscountVnd,
    totalVnd: totalVnd,
  );
}

void _checkRate(int bp) {
  if (bp < 0 || bp > kBasisPointMax) {
    throw CartError.rate;
  }
}
