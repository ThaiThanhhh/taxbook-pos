import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/features/onboarding/data/onboarding_providers.dart';
import 'package:dt13_pos/features/onboarding/data/onboarding_repository.dart';
import 'package:dt13_pos/features/onboarding/domain/business_profile.dart';
import 'package:dt13_pos/features/onboarding/presentation/business_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Báo lỗi khi tên HKD rỗng và mã số thuế sai định dạng', (
    tester,
  ) async {
    final repository = _MemoryOnboardingRepository();
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router, repository));
    await tester.enterText(find.byType(TextField).at(1), '123456789');
    await tester.ensureVisible(find.text('Hoàn tất & Bắt đầu sử dụng'));
    await tester.tap(find.text('Hoàn tất & Bắt đầu sử dụng'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên hộ kinh doanh.'), findsOneWidget);
    expect(
      find.text('Mã số thuế phải gồm đúng 10 hoặc 13 chữ số.'),
      findsOneWidget,
    );
    expect(repository.profile, isNull);
    expect(repository.isCompleted, isFalse);
  });

  testWidgets('Lưu hồ sơ hợp lệ và chuyển sang màn hình bán hàng', (
    tester,
  ) async {
    final repository = _MemoryOnboardingRepository();
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router, repository));
    await tester.enterText(find.byType(TextField).at(0), 'Cửa hàng Hoa Mai');
    await tester.enterText(find.byType(TextField).at(1), '0123456789');
    await tester.enterText(find.byType(TextField).at(2), 'Hà Nội');
    await tester.ensureVisible(find.text('Hoàn tất & Bắt đầu sử dụng'));
    await tester.tap(find.text('Hoàn tất & Bắt đầu sử dụng'));
    await tester.pumpAndSettle();

    expect(repository.profile?.businessName, 'Cửa hàng Hoa Mai');
    expect(repository.profile?.taxCode, '0123456789');
    expect(repository.profile?.address, 'Hà Nội');
    expect(
      find.text('Không thể lưu thông tin lúc này. Vui lòng thử lại.'),
      findsNothing,
    );
    expect(repository.isCompleted, isTrue);
    expect(find.text('Bán hàng'), findsOneWidget);
  });
}

Widget _testApp(GoRouter router, _MemoryOnboardingRepository repository) {
  return ProviderScope(
    overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const BusinessSetupScreen(),
      ),
      GoRoute(
        path: '/sales',
        builder: (_, _) => const Scaffold(body: Text('Bán hàng')),
      ),
    ],
  );
}

class _MemoryOnboardingRepository implements OnboardingRepository {
  BusinessProfile? profile;
  bool isCompleted = false;

  @override
  Future<BusinessProfile?> getBusinessProfile() async => profile;

  @override
  Future<bool> isOnboardingCompleted() async => isCompleted;

  @override
  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    this.profile = profile;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    isCompleted = completed;
  }
}
