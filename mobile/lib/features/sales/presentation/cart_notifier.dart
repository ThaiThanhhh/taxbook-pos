import 'package:dt13_pos/features/sales/domain/cart_calc.dart';
import 'package:flutter/widgets.dart' show Characters;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_notifier.g.dart';

/// Số ký tự tối đa của ghi chú một dòng (đếm theo ký tự người thấy).
const int kCartLineNoteMaxChars = 80;

/// Chữ ký của hàm tính tiền; mặc định là [calcCart].
typedef CartCalculator =
    CartTotals Function(List<CartLine> lines, {required int orderDiscountBp});

/// Tổng của giỏ rỗng. Không phải kết quả của [calcCart] (hàm đó ném
/// [CartError.empty]); chỉ để màn hình hiển thị 0 đ.
const CartTotals kEmptyCartTotals = CartTotals(
  subtotalVnd: 0,
  lineDiscountVnd: 0,
  orderDiscountVnd: 0,
  totalVnd: 0,
);

/// Trạng thái giỏ: danh sách dòng chỉ đọc, tỷ lệ giảm cả đơn và tổng tiền.
final class CartState {
  CartState({
    required List<CartLine> lines,
    required this.orderDiscountBp,
    required this.totals,
  }) : lines = List<CartLine>.unmodifiable(lines);

  final List<CartLine> lines;
  final int orderDiscountBp;
  final CartTotals totals;

  bool get isEmpty => lines.isEmpty;
}

/// Nguồn hàm tính tiền, tách ra để test đếm số lần gọi.
@riverpod
CartCalculator cartCalculator(Ref ref) => calcCart;

/// Giỏ hàng trên bộ nhớ (F05). Không ghi DB, không gọi mạng.
///
/// Giả định: giỏ rỗng là trạng thái hợp lệ của notifier, tổng là
/// [kEmptyCartTotals] và [calcCart] không được gọi. Lỗi [CartError.empty] chỉ
/// xuất hiện khi bấm lưu đơn (SaveOrder, chưa làm ở F05).
///
/// Mọi thao tác tính tổng mới trước rồi mới gán `state`; nếu [calcCart] ném
/// lỗi thì giỏ giữ nguyên. Chỉ số dòng sai ném [RangeError].
// Mất giỏ khi kill app trước lúc lưu là cố ý: giỏ chỉ ở RAM, autoDispose.
@riverpod
class CartNotifier extends _$CartNotifier {
  late CartCalculator _calc;

  @override
  CartState build() {
    _calc = ref.watch(cartCalculatorProvider);
    return CartState(
      lines: const [],
      orderDiscountBp: 0,
      totals: kEmptyCartTotals,
    );
  }

  /// Thêm một dòng mới ở cuối, không gộp với dòng cùng sản phẩm.
  void add(CartLine line) {
    final cutNote = _cutNote(line.note);
    final newLine = cutNote == line.note ? line : line.copyWith(note: cutNote);
    _commit([...state.lines, newLine], state.orderDiscountBp);
  }

  /// Tăng số lượng dòng [lineIndex] thêm 1.
  void increment(int lineIndex) {
    final line = _lineAt(lineIndex);
    _replaceLine(lineIndex, line.copyWith(quantity: line.quantity + 1));
  }

  /// Giảm số lượng dòng [lineIndex] đi 1; về 0 thì xóa dòng.
  void decrement(int lineIndex) {
    final line = _lineAt(lineIndex);
    if (line.quantity <= 1) {
      remove(lineIndex);
      return;
    }
    _replaceLine(lineIndex, line.copyWith(quantity: line.quantity - 1));
  }

  /// Xóa dòng [lineIndex].
  void remove(int lineIndex) {
    _lineAt(lineIndex);
    final lines = [...state.lines]..removeAt(lineIndex);
    _commit(lines, state.orderDiscountBp);
  }

  /// Đặt ghi chú cho dòng [lineIndex], cắt còn [kCartLineNoteMaxChars] ký tự.
  void setLineNote(int lineIndex, String note) {
    final line = _lineAt(lineIndex);
    _replaceLine(lineIndex, line.copyWith(note: _cutNote(note)));
  }

  /// Đặt giảm giá cả đơn theo basis point (1% = 100). Ngoài 0..10000 ném
  /// [CartError.rate] kể cả khi giỏ đang rỗng.
  void setOrderDiscountBp(int bp) {
    if (bp < 0 || bp > kBasisPointMax) {
      throw CartError.rate;
    }
    _commit(state.lines, bp);
  }

  CartLine _lineAt(int lineIndex) {
    RangeError.checkValidIndex(lineIndex, state.lines, 'lineIndex');
    return state.lines[lineIndex];
  }

  void _replaceLine(int lineIndex, CartLine line) {
    final lines = [...state.lines];
    lines[lineIndex] = line;
    _commit(lines, state.orderDiscountBp);
  }

  void _commit(List<CartLine> lines, int orderDiscountBp) {
    final totals = lines.isEmpty
        ? kEmptyCartTotals
        : _calc(lines, orderDiscountBp: orderDiscountBp);
    state = CartState(
      lines: lines,
      orderDiscountBp: orderDiscountBp,
      totals: totals,
    );
  }
}

String _cutNote(String note) {
  final chars = Characters(note);
  if (chars.length <= kCartLineNoteMaxChars) {
    return note;
  }
  return chars.take(kCartLineNoteMaxChars).toString();
}
