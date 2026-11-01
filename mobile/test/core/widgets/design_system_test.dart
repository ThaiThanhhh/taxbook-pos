import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/core/widgets/app_button.dart';
import 'package:dt13_pos/core/widgets/app_text_field.dart';
import 'package:dt13_pos/core/widgets/design_gallery_screen.dart';
import 'package:dt13_pos/core/widgets/money_format.dart';
import 'package:dt13_pos/core/widgets/money_text.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:dt13_pos/core/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MoneyFormat nhóm hàng nghìn và giữ số nguyên', () {
    expect(MoneyFormat.format(1250000), '1.250.000 ₫');
    expect(MoneyFormat.format(0), '0 ₫');
    expect(MoneyFormat.format(-1250000), '-1.250.000 ₫');
    expect(MoneyFormat.parseDigits('1.250.000'), 1250000);
    expect(MoneyFormat.parseDigits(''), isNull);
  });

  testWidgets('PrimaryButton đang tải thì không gọi onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        PrimaryButton(
          label: 'Thanh toán',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('PrimaryButton disabled không nhận bấm', (tester) async {
    const taps = 0;
    await tester.pumpWidget(
      _app(const PrimaryButton(label: 'Lưu', onPressed: null)),
    );

    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(taps, 0);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('PrimaryButton bấm được khi không tải', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(PrimaryButton(label: 'Lưu', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Lưu'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('PrimaryButton.large cao 52', (tester) async {
    await tester.pumpWidget(
      _app(
        PrimaryButton(
          label: 'Thanh toán',
          size: AppButtonSize.large,
          onPressed: () {},
        ),
      ),
    );

    expect(tester.getSize(find.byType(PrimaryButton)).height, 52);
  });

  testWidgets('AppTextField tiền trả về int và chèn dấu chấm', (tester) async {
    int? amount;
    await tester.pumpWidget(
      _app(
        AppTextField(
          kind: AppTextFieldKind.money,
          onMoneyChanged: (value) => amount = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1250000');
    await tester.pump();

    expect(amount, 1250000);
    expect(find.text('1.250.000'), findsOneWidget);
  });

  testWidgets('AppTextField tiền để trống thì trả null', (tester) async {
    int? amount = 1;
    await tester.pumpWidget(
      _app(
        AppTextField(
          kind: AppTextFieldKind.money,
          onMoneyChanged: (value) => amount = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '50');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    expect(amount, isNull);
  });

  testWidgets('AppTextField mã số thuế chặn chữ', (tester) async {
    await tester.pumpWidget(
      _app(const AppTextField(kind: AppTextFieldKind.taxCode)),
    );

    await tester.enterText(find.byType(TextField), 'ab12c3');
    await tester.pump();

    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('MoneyText định dạng đúng, số âm và 0', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [MoneyText(1250000), MoneyText(0), MoneyText(-1250000)],
        ),
      ),
    );

    expect(find.text('1.250.000 ₫'), findsOneWidget);
    expect(find.text('0 ₫'), findsOneWidget);
    expect(find.text('-1.250.000 ₫'), findsOneWidget);

    final negative = tester.widget<Text>(find.text('-1.250.000 ₫'));
    expect(negative.style?.color, AppColors.error);
    expect(negative.textAlign, TextAlign.right);
    expect(
      negative.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );

    final zero = tester.widget<Text>(find.text('0 ₫'));
    expect(zero.style?.color, AppColors.textPrimary);
  });

  testWidgets('StatusChip hiện chữ và icon cho 3 trạng thái', (tester) async {
    await tester.pumpWidget(
      _app(
        const Wrap(
          children: [
            StatusChip(SyncStatus.synced),
            StatusChip(SyncStatus.pending),
            StatusChip(SyncStatus.failed),
          ],
        ),
      ),
    );

    expect(find.text('Đã đồng bộ'), findsOneWidget);
    expect(find.text('Chờ gửi'), findsOneWidget);
    expect(find.text('Lỗi'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });

  testWidgets('DesignGalleryScreen dựng được trên màn hẹp', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const DesignGalleryScreen()),
    );
    await tester.pump();

    expect(find.text('Thư viện giao diện'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Thử lại'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}
