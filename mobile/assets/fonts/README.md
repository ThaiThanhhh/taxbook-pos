# Be Vietnam Pro

Font tiếng Việt của design system, giấy phép SIL Open Font License 1.1
(xem [OFL.txt](OFL.txt)). Đóng gói sẵn để app chạy offline — không dùng `google_fonts`.

| File | Trọng số |
|---|---|
| `BeVietnamPro-Regular.ttf` | 400 |
| `BeVietnamPro-Medium.ttf` | 500 |
| `BeVietnamPro-SemiBold.ttf` | 600 |
| `BeVietnamPro-Bold.ttf` | 700 |

Khai báo trong `pubspec.yaml`, family `BeVietnamPro`.

## Tải lại khi cần

Nguồn: [google/fonts](https://github.com/google/fonts/tree/main/ofl/bevietnampro)
(bản static, cùng bộ với [bettergui/BeVietnamPro](https://github.com/bettergui/BeVietnamPro)).

```powershell
$dir = "mobile/assets/fonts"
$base = "https://raw.githubusercontent.com/google/fonts/main/ofl/bevietnampro"
foreach ($f in @(
  "BeVietnamPro-Regular.ttf",
  "BeVietnamPro-Medium.ttf",
  "BeVietnamPro-SemiBold.ttf",
  "BeVietnamPro-Bold.ttf",
  "OFL.txt"
)) {
  Invoke-WebRequest "$base/$f" -OutFile (Join-Path $dir $f)
}
```

Đặt đúng 4 file `.ttf` và `OFL.txt` vào thư mục này. Không đổi tên file
nếu chưa sửa đường dẫn trong `pubspec.yaml`.
