import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/features/onboarding/presentation/user_guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hiển thị đủ bốn bước hướng dẫn', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const UserGuideScreen()),
    );

    expect(find.text('Thiết lập Hộ kinh doanh'), findsOneWidget);
    expect(find.text('Bán hàng & Ghi nhận doanh thu'), findsOneWidget);
    expect(find.text('Chụp hóa đơn chi phí bằng AI (OCR)'), findsOneWidget);
    expect(find.text('Xem báo cáo & Tự tính thuế 2026'), findsOneWidget);
  });

  testWidgets('Mở rộng được câu hỏi thường gặp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const UserGuideScreen()),
    );

    const question = 'Mất kết nối Internet có bán hàng được không?';
    await tester.scrollUntilVisible(find.text(question), 300);
    await tester.tap(find.text(question));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Ứng dụng lưu đơn hàng cục bộ trên thiết bị'),
      findsOneWidget,
    );
  });
}
