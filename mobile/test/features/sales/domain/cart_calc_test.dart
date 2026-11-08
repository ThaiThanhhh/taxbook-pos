import 'package:dt13_pos/features/sales/domain/cart_calc.dart';
import 'package:flutter_test/flutter_test.dart';

const _comSuon = CartLine(
  productId: 'com-suon',
  name: 'Cơm sườn',
  unitPriceVnd: 45000,
  quantity: 1,
);
const _traDa = CartLine(
  productId: 'tra-da',
  name: 'Trà đá',
  unitPriceVnd: 5000,
  quantity: 1,
);

CartLine _line({
  int unitPriceVnd = 45000,
  int quantity = 1,
  int lineDiscountBp = 0,
}) => CartLine(
  productId: 'com-suon',
  name: 'Cơm sườn',
  unitPriceVnd: unitPriceVnd,
  quantity: quantity,
  lineDiscountBp: lineDiscountBp,
);

void main() {
  test('f02_empty', () {
    expect(() => calcCart([], orderDiscountBp: 0), throwsA(CartError.empty));
  });

  test('f02_qty0', () {
    expect(
      () => calcCart([_line(quantity: 0)], orderDiscountBp: 0),
      throwsA(CartError.quantity),
    );
  });

  test('f02_price0', () {
    expect(
      () => calcCart([_line(unitPriceVnd: 0)], orderDiscountBp: 0),
      throwsA(CartError.price),
    );
  });

  test('f02_one', () {
    final totals = calcCart([_comSuon], orderDiscountBp: 0);
    expect(totals.subtotalVnd, 45000);
    expect(totals.lineDiscountVnd, 0);
    expect(totals.orderDiscountVnd, 0);
    expect(totals.totalVnd, 45000);
  });

  test('f02_qty2', () {
    final totals = calcCart([_line(quantity: 2)], orderDiscountBp: 0);
    expect(totals.totalVnd, 90000);
  });

  test('f02_two_items', () {
    final totals = calcCart([_comSuon, _traDa], orderDiscountBp: 0);
    expect(totals.totalVnd, 50000);
  });

  test('f02_line_10pct', () {
    final totals = calcCart([_line(lineDiscountBp: 1000)], orderDiscountBp: 0);
    expect(totals.subtotalVnd, 45000);
    expect(totals.lineDiscountVnd, 4500);
    expect(totals.orderDiscountVnd, 0);
    expect(totals.totalVnd, 40500);
  });

  test('f02_trunc_1', () {
    final totals = calcCart([
      _line(unitPriceVnd: 10001, lineDiscountBp: 1),
    ], orderDiscountBp: 0);
    expect(totals.lineDiscountVnd, 1);
    expect(totals.totalVnd, 10000);
  });

  test('f02_trunc_0', () {
    final totals = calcCart([
      _line(unitPriceVnd: 9999, lineDiscountBp: 1),
    ], orderDiscountBp: 0);
    expect(totals.lineDiscountVnd, 0);
    expect(totals.totalVnd, 9999);
  });

  test('f02_order_10pct', () {
    final totals = calcCart([_comSuon, _traDa], orderDiscountBp: 1000);
    expect(totals.subtotalVnd, 50000);
    expect(totals.lineDiscountVnd, 0);
    expect(totals.orderDiscountVnd, 5000);
    expect(totals.totalVnd, 45000);
  });

  test('f02_bp_over', () {
    expect(
      () => calcCart([_comSuon], orderDiscountBp: 10001),
      throwsA(CartError.rate),
    );
  });

  test('f02_twenty', () {
    final lines = List<CartLine>.generate(20, (_) => _line());
    final before = List<CartLine>.of(lines);
    final totals = calcCart(lines, orderDiscountBp: 0);
    expect(totals.totalVnd, 900000);
    expect(lines, hasLength(20));
    for (var i = 0; i < lines.length; i++) {
      expect(identical(lines[i], before[i]), isTrue);
      expect(lines[i].productId, 'com-suon');
      expect(lines[i].quantity, 1);
    }
  });

  test('f02_big', () {
    final totals = calcCart([
      _line(unitPriceVnd: 2000000000),
    ], orderDiscountBp: 0);
    expect(totals.totalVnd, 2000000000);
    expect(totals.totalVnd, isA<int>());
  });

  test('f02_same_id', () {
    final first = _line();
    final second = _line();
    final lines = [first, second];
    final totals = calcCart(lines, orderDiscountBp: 0);
    expect(lines, hasLength(2));
    expect(identical(lines[0], first), isTrue);
    expect(identical(lines[1], second), isTrue);
    expect(lines[0].productId, 'com-suon');
    expect(lines[1].productId, 'com-suon');
    expect(lines[0].quantity, 1);
    expect(lines[1].quantity, 1);
    expect(totals.totalVnd, 90000);
  });

  test('f02_negative_price', () {
    expect(
      () => calcCart([_line(unitPriceVnd: -1)], orderDiscountBp: 0),
      throwsA(CartError.price),
    );
  });

  test('f02_line_over', () {
    expect(
      () => calcCart([_line(lineDiscountBp: 10001)], orderDiscountBp: 0),
      throwsA(CartError.rate),
    );
  });

  // Biên bổ sung: giữ nguyên toàn bộ 16 ca bắt buộc ở trên.
  test('f02_negative_quantity', () {
    expect(
      () => calcCart([_line(quantity: -1)], orderDiscountBp: 0),
      throwsA(CartError.quantity),
    );
  });

  test('f02_negative_order_rate', () {
    expect(
      () => calcCart([_comSuon], orderDiscountBp: -1),
      throwsA(CartError.rate),
    );
  });

  test('f02_negative_line_rate', () {
    expect(
      () => calcCart([_line(lineDiscountBp: -1)], orderDiscountBp: 0),
      throwsA(CartError.rate),
    );
  });

  test('f02_line_100pct_is_valid_zero', () {
    final totals = calcCart([_line(lineDiscountBp: 10000)], orderDiscountBp: 0);
    expect(totals.subtotalVnd, 45000);
    expect(totals.lineDiscountVnd, 45000);
    expect(totals.orderDiscountVnd, 0);
    expect(totals.totalVnd, 0);
  });

  test('f02_order_100pct_is_valid_zero', () {
    final totals = calcCart([_comSuon], orderDiscountBp: 10000);
    expect(totals.subtotalVnd, 45000);
    expect(totals.lineDiscountVnd, 0);
    expect(totals.orderDiscountVnd, 45000);
    expect(totals.totalVnd, 0);
  });

  test('f02_order_discount_after_line_discount', () {
    final totals = calcCart([
      _line(lineDiscountBp: 1000),
      _traDa,
    ], orderDiscountBp: 1000);
    expect(totals.subtotalVnd, 50000);
    expect(totals.lineDiscountVnd, 4500);
    expect(totals.orderDiscountVnd, 4550);
    expect(totals.totalVnd, 40950);
  });

  test('f02_line_truncation_after_quantity', () {
    final totals = calcCart([
      _line(unitPriceVnd: 9999, quantity: 2, lineDiscountBp: 1),
    ], orderDiscountBp: 0);
    expect(totals.subtotalVnd, 19998);
    expect(totals.lineDiscountVnd, 1);
    expect(totals.totalVnd, 19997);
  });

  test('f02_same_id_truncates_each_line_separately', () {
    final lines = [
      _line(unitPriceVnd: 9999, lineDiscountBp: 1),
      _line(unitPriceVnd: 9999, lineDiscountBp: 1),
    ];
    final totals = calcCart(lines, orderDiscountBp: 0);
    expect(lines, hasLength(2));
    expect(totals.subtotalVnd, 19998);
    expect(totals.lineDiscountVnd, 0);
    expect(totals.totalVnd, 19998);
  });

  test('f02_order_truncation', () {
    final above = calcCart([_line(unitPriceVnd: 10001)], orderDiscountBp: 1);
    expect(above.orderDiscountVnd, 1);
    expect(above.totalVnd, 10000);
    final below = calcCart([_line(unitPriceVnd: 9999)], orderDiscountBp: 1);
    expect(below.orderDiscountVnd, 0);
    expect(below.totalVnd, 9999);
  });

  test('f02_validates_later_lines_even_after_full_order_discount', () {
    expect(
      () => calcCart([_comSuon, _line(quantity: 0)], orderDiscountBp: 10000),
      throwsA(CartError.quantity),
    );
  });

  test('f02_accepts_unmodifiable_lines_and_is_repeatable', () {
    final lines = List<CartLine>.unmodifiable([_comSuon, _traDa]);
    final first = calcCart(lines, orderDiscountBp: 1000);
    final second = calcCart(lines, orderDiscountBp: 1000);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(lines, orderedEquals([_comSuon, _traDa]));
  });

  test('f02_value_types', () {
    final sameLine = _line();
    expect(sameLine, _comSuon);
    expect(sameLine.hashCode, _comSuon.hashCode);
    expect(_line(quantity: 2), isNot(_comSuon));
    expect(
      calcCart([_comSuon], orderDiscountBp: 0),
      const CartTotals(
        subtotalVnd: 45000,
        lineDiscountVnd: 0,
        orderDiscountVnd: 0,
        totalVnd: 45000,
      ),
    );
    expect(
      calcCart([_comSuon], orderDiscountBp: 0),
      isNot(calcCart([_comSuon], orderDiscountBp: 1000)),
    );
  });
}
