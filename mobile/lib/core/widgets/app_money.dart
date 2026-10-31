import 'package:flutter/material.dart';

class AppMoney extends StatelessWidget {
  const AppMoney({
    super.key,
    required this.amount,
    this.style,
  });

  final int amount;
  final TextStyle? style;

  static String formatAmount(int amount) {
    final value = amount.toString();
    final isNegative = value.startsWith('-');
    final digits = isNegative ? value.substring(1) : value;
    final formatted = StringBuffer();

    if (isNegative) {
      formatted.write('-');
    }

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write('.');
      }
      formatted.write(digits[index]);
    }

    return '${formatted.toString()} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatAmount(amount),
      style: style,
    );
  }
}