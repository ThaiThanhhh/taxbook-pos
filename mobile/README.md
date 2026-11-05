# ĐT13 POS — mobile (Flutter)

App bán hàng và tính thuế cho hộ kinh doanh, offline-first. Android + iOS.

| Thành phần | Lựa chọn |
|---|---|
| Flutter / Dart | stable 3.47 / Dart 3.13 (`sdk: ^3.12.0`) |
| State | `flutter_riverpod` 3 + `riverpod_annotation`/`riverpod_generator` |
| Routing | `go_router` |
| Network | `dio` (`lib/core/network/api_client.dart`) |
| Token | `flutter_secure_storage` 11.2.0; rủi ro: plugin native, cần thử trên máy thật |
| Lint | `flutter_lints` + rule nghiêm hơn trong `analysis_options.yaml` |
| UI | Material 3, font Be Vietnam Pro (offline), token trong `lib/core/theme/` |

## Cài đặt lần đầu

```bash
cd mobile
flutter pub get
dart run build_runner build -d     # sinh *.g.dart (không commit, trừ lib/core/db/app_database.g.dart)
```

Khi đang code provider: `dart run build_runner watch -d`.

## Chạy

Môi trường chọn bằng `--dart-define-from-file` (các file trong `config/env/`):

```bash
flutter run --dart-define-from-file=config/env/dev.json
flutter run --dart-define-from-file=config/env/staging.json
flutter run --release --dart-define-from-file=config/env/prod.json
```

- `dev.json` trỏ tới `http://10.0.2.2:3000/api/v1` (localhost của máy host, nhìn từ Android emulator).
  iOS simulator hoặc máy thật: sửa thành `http://localhost:3000/api/v1` hoặc IP LAN của máy chạy backend.
  Mock Prism (`docker compose up mock`) chạy ở cổng `4010`.
- HTTP cleartext chỉ được bật ở bản debug Android (`android/app/src/debug/AndroidManifest.xml`)
  và cho mạng local trên iOS (`NSAllowsLocalNetworking`).
- Không ghi secret vào `config/env/*.json`; các file này được commit.

## F04 — phiên đăng nhập local

- Giữ interface `TokenStorage`; provider production dùng `SecureTokenStorage` với
  `flutter_secure_storage` **11.2.0** (khóa phiên bản). `build_runner` vẫn 2.16.2.
- Rủi ro: plugin native Keystore/Keychain, cần rebuild và kiểm trên thiết bị thật;
  unit/widget test chỉ kiểm adapter bằng mock, không chứng minh mã hóa native.
- Splash chờ đọc token xong mới mở `/sales` hoặc `/login`; lỗi kho khóa ở lại
  Splash với nút Thử lại. Android dùng `resetOnError: false`, không tự xóa kho.
- Dev/staging: đúng 6 chữ số ASCII mới lưu `dev-token`; đây không phải OTP thật.
  Prod không lưu token và hiện “Chưa nối máy chủ”. Chưa gọi API xác thực.
- Đăng xuất chờ xóa đúng key access token rồi về `/login`, không gọi DB/xóa orders.
- Android hiện minSdk 24. Backup rules chỉ loại hai shared preferences của plugin,
  không thay chính sách backup DB. iOS cần kiểm Keychain/signing trên macOS trước phát hành.

Thử Android thật sau khi `flutter pub get` (dừng/chạy lại app, không chỉ hot reload):
1. Dev hoặc staging: nhập `12345`, bấm đăng nhập → vẫn `/login`.
2. Nhập `123456` → `/sales`; force-stop rồi mở lại → qua Splash đến `/sales`,
   không xuất hiện `/login`.
3. Mở `/settings`, Đăng xuất → `/login`; mở lại vẫn `/login`; dữ liệu đơn còn nguyên.
4. Prod trên dữ liệu sạch: bấm đăng nhập → hiện “Chưa nối máy chủ”, không ghi token.

## Design system

Font Be Vietnam Pro (OFL) nằm trong `assets/fonts/` — xem `assets/fonts/README.md`
nếu cần tải lại. Không dùng `google_fonts`.

Màn kiểm tra widget: chạy debug rồi mở `/design-gallery`
(có link "Thư viện giao diện" trên các màn placeholder). Route này không có trong bản release.

## Kiểm tra trước khi mở PR

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Build:

```bash
flutter build apk --dart-define-from-file=config/env/staging.json
flutter build ipa --dart-define-from-file=config/env/prod.json   # cần macOS + Xcode
```

## Cấu trúc

```
lib/
  main.dart            # đọc AppEnv, khởi tạo ProviderScope
  app.dart             # MaterialApp.router
  core/                # Gia Bảo (db, network, router, constants, utils) · Mai Trinh (theme)
    constants/         # AppEnv (flavor, baseUrl), AppConstants
    db/                # LocalDatabase + AppDatabase drift (schema v1, F01)
    network/           # ApiClient, AuthInterceptor, TokenStorage, providers
    router/            # AppRoutes, appRouterProvider, PlaceholderScaffold
    theme/             # AppTheme
    utils/             # AppLogger (thay cho print)
  features/
    auth/              # /splash, /login
    sales/             # /sales, /history       — Gia Bảo
    payment/           # /payment               — Gia Bảo
    sync/              # hàng đợi sync offline  — Gia Bảo
    settings/          # /settings
    ledger/            # Mai Trinh (đang trống)
    reports/           # Mai Trinh (đang trống)
```

Mỗi feature chia `data/` (DTO, datasource, repository impl) → `domain/` (entity,
interface repository, Dart thuần) → `presentation/` (screen, widget, provider UI).
Feature không import trực tiếp lẫn nhau; dùng chung thì đưa vào `core/`.

Thêm màn mới: thêm hằng số vào `AppRoutes`, thêm `GoRoute` trong
`core/router/app_router.dart`. Các test trong `test/app_smoke_test.dart` kiểm tra
mọi route trong `AppRoutes` đều đã được khai báo.
