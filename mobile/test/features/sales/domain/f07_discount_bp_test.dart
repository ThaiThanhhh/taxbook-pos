import 'package:dt13_pos/features/sales/domain/discount_bp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('f07_10k_of_100k', () {
    expect(vndToOrderBp(10000, 100000), 1000);
  });

  test('f07_1_of_3', () {
    // 1 * 10000 ~/ 3 = 3333: phần dư bị cắt, không làm tròn lên 3334.
    expect(vndToOrderBp(1, 3), 3333);
  });

  test('f07_over', () {
    expect(() => vndToOrderBp(100001, 100000), throwsArgumentError);
  });

  test('f07_zero_subtotal', () {
    expect(() => vndToOrderBp(0, 0), throwsArgumentError);
  });

  test('f07_negative_subtotal', () {
    expect(() => vndToOrderBp(0, -1), throwsArgumentError);
  });

  test('f07_negative_discount', () {
    expect(() => vndToOrderBp(-1, 100000), throwsArgumentError);
  });

  test('f07_zero_discount', () {
    expect(vndToOrderBp(0, 100000), 0);
  });

  test('f07_full_discount', () {
    expect(vndToOrderBp(100000, 100000), 10000);
  });

  test('f07_5k_of_50k', () {
    expect(vndToOrderBp(5000, 50000), 1000);
  });

  test('f07_truncate_not_round', () {
    // 2 * 10000 / 3 = 6666,67 -> 6666.
    expect(vndToOrderBp(2, 3), 6666);
    // 999 * 10000 / 100000 = 99,9 -> 99.
    expect(vndToOrderBp(999, 100000), 99);
  });

  test('f07_huge_no_overflow', () {
    // Số lớn nhất parseDigits có thể trả (15 chữ số) vẫn không tràn int.
    const big = 999999999999999;
    expect(() => vndToOrderBp(big, big), throwsArgumentError);
    expect(vndToOrderBp(kMaxDiscountVndForBp, kMaxDiscountVndForBp), 10000);
  });
}
