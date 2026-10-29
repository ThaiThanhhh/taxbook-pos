# Quy tắc làm việc

## Nhánh và Pull Request

- `main` được bảo vệ: không đẩy trực tiếp. Mọi thay đổi qua Pull Request, cần CI xanh và ít nhất 1 review.
- Tên nhánh: `<chủ>/<việc>`, ví dụ `gia-bao/sync-queue`, `hoai-bao/tax-engine`, `quang-dung/sync-sales`.
- Nhánh sống không quá 3 ngày. PR nhỏ (gợi ý dưới 400 dòng thay đổi) để review nhanh.
- Review chéo: Gia Bảo và Mai Trinh (mobile); Quang Dũng và Hoài Bảo (backend); Văn Thành và Hoài Bảo khi đổi cách AI đọc dữ liệu; Tấn Tài review mọi PR đổi CI hoặc test; Ngọc Thái review mọi PR đổi `api/openapi.yaml` và `config/tax/`.

## Khi hai người cùng cần sửa một thứ

1. File trong thư mục người khác: mở issue nói cần gì, để chủ sửa hoặc chấp nhận PR của bạn.
2. `api/openapi.yaml`: mở PR nhỏ chỉ đổi hợp đồng, gắn Ngọc Thái và cả hai bên dùng endpoint đó. Hợp nhất trước rồi mới sửa code.
3. Migration cơ sở dữ liệu: xin số thứ tự từ Quang Dũng. Không sửa migration đã hợp nhất, tạo migration mới.
4. Quy tắc nghiệp vụ hoặc số liệu thuế: Ngọc Thái quyết sau khi hỏi giảng viên, ghi vào SRS thành `BR-xxx`.

## Khi bị chặn

Chờ quá nửa ngày chưa có đầu ra của người kia: nhắn trực tiếp họ. Sau 1 ngày: báo Ngọc Thái để cắt phạm vi hoặc chia lại việc. Trong lúc chờ, làm tiếp trên mock hoặc dữ liệu giả lập.

## Nhịp làm việc

- Họp đứng 10 phút mỗi ngày: hôm qua làm gì, hôm nay làm gì, đang chờ ai.
- Cuối tuần: demo 30 phút một luồng đầu-cuối, rồi retro 15 phút.
