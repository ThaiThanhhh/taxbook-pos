/// F07 – đổi số tiền giảm cả đơn (VND) sang basis point. Dart thuần.
library;

import 'package:dt13_pos/features/sales/domain/cart_calc.dart';

/// Số tiền giảm lớn nhất mà `discountVnd * 10000` vẫn chưa tràn int 64-bit.
const int kMaxDiscountVndForBp = 922337203685477;

/// Đổi [discountVnd] trên [subtotalVnd] thành basis point (1% = 100).
///
/// Ném [ArgumentError] khi:
/// - [subtotalVnd] < 1,
/// - [discountVnd] < 0,
/// - [discountVnd] > [subtotalVnd] (không kẹp về [subtotalVnd]),
/// - [discountVnd] lớn tới mức phép nhân tràn int.
int vndToOrderBp(int discountVnd, int subtotalVnd) {
  if (subtotalVnd < 1) {
    throw ArgumentError.value(subtotalVnd, 'subtotalVnd', 'phải từ 1 trở lên');
  }
  if (discountVnd < 0) {
    throw ArgumentError.value(discountVnd, 'discountVnd', 'không được âm');
  }
  if (discountVnd > subtotalVnd) {
    throw ArgumentError.value(
      discountVnd,
      'discountVnd',
      'lớn hơn subtotalVnd ($subtotalVnd)',
    );
  }
  if (discountVnd > kMaxDiscountVndForBp) {
    throw ArgumentError.value(discountVnd, 'discountVnd', 'quá lớn');
  }
  // Phần dư bị cắt (~/), không làm tròn: 1 trên 3 ra 3333, không phải 3334.
  return discountVnd * kBasisPointMax ~/ subtotalVnd;
}
