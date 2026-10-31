# ĐT13 POS — mobile (Flutter)

App bán hàng và tính thuế cho hộ kinh doanh, offline-first. Android + iOS.

| Thành phần | Lựa chọn |
|---|---|
| Flutter / Dart | stable 3.47 / Dart 3.13 (`sdk: ^3.12.0`) |
| State | `flutter_riverpod` 3 + `riverpod_annotation`/`riverpod_generator` |
| Routing | `go_router` |
| Network | `dio` (`lib/core/network/api_client.dart`) |
| Lint | `flutter_lints` + rule nghiêm hơn trong `analysis_options.yaml` |

## Cài đặt lần đầu

```bash
cd mobile
flutter pub get
dart run build_runner build -d     # sinh *.g.dart (không commit)
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
    db/                # LocalDatabase (interface, sẽ thay bằng SQLite)
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
