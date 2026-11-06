import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:flutter/services.dart';

/// Gõ tiền: chỉ giữ chữ số, tự thêm dấu chấm ngăn cách hàng nghìn.
/// Con trỏ về cuối chuỗi — phù hợp nhập nhanh ngoài quầy.
class VndInputFormatter extends TextInputFormatter {
  const VndInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final parsed = MoneyFormat.parseDigits(newValue.text);
    if (parsed == null) return TextEditingValue.empty;
    final formatted = MoneyFormat.group(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
