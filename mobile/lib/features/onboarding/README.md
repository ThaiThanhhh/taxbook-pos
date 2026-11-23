# Onboarding và khai báo ban đầu

## Đăng ký đường dẫn

Trong `mobile/lib/core/router/app_routes.dart`, thêm các hằng số:

```dart
static const String onboarding = '/onboarding';
static const String welcome = '/welcome';
```

Đăng ký `WelcomeTourScreen` và `BusinessSetupScreen` trong
`mobile/lib/core/router/app_router.dart`.

## Điều hướng từ SplashScreen

Trong `mobile/lib/features/auth/presentation/splash_screen.dart`, đọc
`isOnboardingCompleted()` trước. Nếu kết quả là `false`, điều hướng đến
`AppRoutes.welcome`. Nếu đã hoàn tất, kiểm tra access token: có token thì đến
`AppRoutes.sales`, chưa có token thì đến `AppRoutes.login`.

## Lưu trữ

Hồ sơ hộ kinh doanh và trạng thái hoàn tất được lưu cục bộ bằng
`SharedPreferences`. Khi bổ sung bảng hồ sơ vào Drift, có thể chuyển repository
sang lưu hồ sơ trong cơ sở dữ liệu mà không đổi giao diện của các màn hình.
