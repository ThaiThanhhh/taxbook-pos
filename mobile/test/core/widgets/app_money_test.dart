import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/widgets/app_money.dart';

void main() {
  testWidgets('formats amount with dot separators and dong suffix', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppMoney(amount: 1250000),
      ),
    );

    expect(find.text('1.250.000 ₫'), findsOneWidget);
  });
}