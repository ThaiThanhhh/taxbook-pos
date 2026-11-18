import 'package:dt13_pos/features/sales/domain/cart_calc.dart';
import 'package:dt13_pos/features/sales/presentation/cart_notifier.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Bọc [calcCart] để ghi lại mọi lần gọi và đầu vào của nó.
final class _SpyCalc {
  final List<List<CartLine>> calls = [];

  CartTotals call(List<CartLine> lines, {required int orderDiscountBp}) {
    calls.add(List<CartLine>.of(lines));
    return calcCart(lines, orderDiscountBp: orderDiscountBp);
  }
}

typedef _Harness = ({
  ProviderContainer container,
  CartNotifier notifier,
  _SpyCalc spy,
});

_Harness _setUp() {
  final spy = _SpyCalc();
  final container = ProviderContainer(
    overrides: [cartCalculatorProvider.overrideWithValue(spy.call)],
  );
  addTearDown(container.dispose);
  // Provider là autoDispose: giữ một listener để state không bị hủy giữa chừng.
  final sub = container.listen(cartProvider, (_, _) {});
  addTearDown(sub.close);
  return (
    container: container,
    notifier: container.read(cartProvider.notifier),
    spy: spy,
  );
}

CartState _state(_Harness h) => h.container.read(cartProvider);

/// Tổng trong state phải đúng bằng calcCart tính lại từ chính state đó.
void _expectNoRecompute(_Harness h) {
  final state = _state(h);
  if (state.lines.isEmpty) {
    expect(state.totals, kEmptyCartTotals);
    return;
  }
  final expected = calcCart(
    state.lines,
    orderDiscountBp: state.orderDiscountBp,
  );
  expect(state.totals.totalVnd, expected.totalVnd);
  expect(state.totals, expected);
}

void main() {
  test('f05_initial_empty', () {
    final h = _setUp();
    final state = _state(h);
    expect(state.lines, isEmpty);
    expect(state.isEmpty, isTrue);
    expect(state.orderDiscountBp, 0);
    expect(state.totals, kEmptyCartTotals);
    expect(h.spy.calls, isEmpty);
  });

  test('f05_add_two', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..add(_traDa);
    final state = _state(h);
    expect(state.lines, orderedEquals([_comSuon, _traDa]));
    expect(state.totals.totalVnd, 50000);
  });

  test('f05_add_same_product_no_merge', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..add(_comSuon);
    final state = _state(h);
    expect(state.lines, hasLength(2));
    expect(state.lines[0].quantity, 1);
    expect(state.lines[1].quantity, 1);
    expect(state.totals.totalVnd, 90000);
  });

  test('f05_increment', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..increment(0);
    final state = _state(h);
    expect(state.lines.single.quantity, 2);
    expect(state.totals.totalVnd, 90000);
  });

  test('f05_decrement_removes', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..decrement(0);
    final state = _state(h);
    expect(state.lines, isEmpty);
    expect(state.totals, kEmptyCartTotals);
    // calcCart chỉ được gọi một lần (lúc add), không bao giờ với quantity 0
    // hay với giỏ rỗng.
    expect(h.spy.calls, hasLength(1));
    for (final lines in h.spy.calls) {
      expect(lines, isNotEmpty);
      expect(lines.every((line) => line.quantity >= 1), isTrue);
    }
  });

  test('f05_decrement_keeps_line_above_one', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..increment(0)
      ..decrement(0);
    final state = _state(h);
    expect(state.lines.single.quantity, 1);
    expect(state.totals.totalVnd, 45000);
  });

  test('f05_remove', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..add(_traDa)
      ..remove(0);
    final state = _state(h);
    expect(state.lines, orderedEquals([_traDa]));
    expect(state.totals.totalVnd, 5000);
  });

  test('f05_discount', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..add(_traDa)
      ..setOrderDiscountBp(1000);
    final state = _state(h);
    expect(state.orderDiscountBp, 1000);
    expect(state.totals.orderDiscountVnd, 5000);
    expect(state.totals.totalVnd, 45000);
  });

  test('f05_discount_set_before_add', () {
    final h = _setUp();
    h.notifier
      ..setOrderDiscountBp(1000)
      ..add(_comSuon)
      ..add(_traDa);
    expect(_state(h).totals.totalVnd, 45000);
  });

  test('f05_discount_out_of_range_keeps_state', () {
    final h = _setUp();
    h.notifier.add(_comSuon);
    final before = _state(h);
    expect(() => h.notifier.setOrderDiscountBp(10001), throwsA(CartError.rate));
    expect(() => h.notifier.setOrderDiscountBp(-1), throwsA(CartError.rate));
    expect(identical(_state(h), before), isTrue);
  });

  test('f05_note_cut', () {
    final h = _setUp();
    h.notifier
      ..add(_comSuon)
      ..setLineNote(0, 'a' * 100);
    final state = _state(h);
    expect(state.lines.single.note, 'a' * 80);
    expect(state.lines.single.note.length, 80);
    expect(state.totals.totalVnd, 45000);
  });

  test('f05_note_cut_vietnamese_keeps_whole_chars', () {
    final h = _setUp();
    // "ệ" dạng tổ hợp (e + dấu nặng + dấu mũ) là 1 ký tự nhưng 3 code unit.
    const combined = 'e\u0323\u0302';
    h.notifier
      ..add(_comSuon)
      ..setLineNote(0, combined * 100);
    final note = _state(h).lines.single.note;
    expect(note, combined * 80);
  });

  test('f05_note_cut_on_add', () {
    final h = _setUp();
    h.notifier.add(
      const CartLine(
        productId: 'com-suon',
        name: 'Cơm sườn',
        unitPriceVnd: 45000,
        quantity: 1,
        note:
            'ít cơm, thêm mỡ hành, không lấy dưa leo, canh để riêng, '
            'gói mang về giúp em nhé, cảm ơn',
      ),
    );
    final note = _state(h).lines.single.note;
    expect(note.characters.length, 80);
    expect(note, startsWith('ít cơm, thêm mỡ hành'));
  });

  test('f05_bad_index_throws_and_keeps_state', () {
    final h = _setUp();
    h.notifier.add(_comSuon);
    final before = _state(h);
    expect(() => h.notifier.increment(1), throwsRangeError);
    expect(() => h.notifier.decrement(-1), throwsRangeError);
    expect(() => h.notifier.remove(5), throwsRangeError);
    expect(() => h.notifier.setLineNote(1, 'x'), throwsRangeError);
    expect(identical(_state(h), before), isTrue);
  });

  test('f05_calc_error_keeps_state', () {
    final h = _setUp();
    h.notifier.add(_comSuon);
    final before = _state(h);
    expect(
      () => h.notifier.add(
        const CartLine(
          productId: 'loi',
          name: 'Món lỗi',
          unitPriceVnd: 0,
          quantity: 1,
        ),
      ),
      throwsA(CartError.price),
    );
    expect(identical(_state(h), before), isTrue);
  });

  test('f05_lines_unmodifiable', () {
    final h = _setUp();
    h.notifier.add(_comSuon);
    expect(() => _state(h).lines.add(_traDa), throwsUnsupportedError);
  });

  test('f05_auto_dispose_drops_cart', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(cartProvider, (_, _) {});
    container.read(cartProvider.notifier).add(_comSuon);
    expect(container.read(cartProvider).lines, hasLength(1));
    // Không còn ai nghe -> provider tự hủy (không keepAlive), giỏ mất theo.
    sub.close();
    await container.pump();
    expect(container.exists(cartProvider), isFalse);
    expect(container.read(cartProvider).lines, isEmpty);
  });

  test('f05_no_recompute', () {
    final h = _setUp();
    final steps = <void Function()>[
      () => h.notifier.add(_comSuon),
      () => h.notifier.add(_traDa),
      () => h.notifier.increment(0),
      () => h.notifier.setOrderDiscountBp(1000),
      () => h.notifier.setLineNote(1, 'b' * 100),
      () => h.notifier.decrement(0),
      () => h.notifier.decrement(1),
      () => h.notifier.remove(0),
      () => h.notifier.add(_traDa),
      () => h.notifier.setOrderDiscountBp(0),
    ];
    for (final step in steps) {
      step();
      _expectNoRecompute(h);
    }
  });
}
