# DT13 – "Bán là có sổ" cho hộ kinh doanh

Ứng dụng di động giúp hộ kinh doanh: mỗi lần bán hàng tự sinh hóa đơn, tự ghi sổ doanh thu và tự tính thuế phải nộp theo kỳ. Bán được cả khi mất mạng.

## Nhóm và chủ thư mục

| Người | Vai trò | Thư mục sở hữu |
| --- | --- | --- |
| Ngọc Thái | BA / Lead | `docs/`, `api/openapi.yaml`, `config/tax/` |
| Tấn Tài | QA / DevOps | `tests/`, `infra/`, `.github/workflows/`, `docker-compose.yml` |
| Quang Dũng | Backend Sales & Invoice | `backend/sales/`, khung `backend/common/` |
| Hoài Bảo | Backend Ledger & Tax | `backend/ledger/`, `backend/tax/` |
| Gia Bảo | Mobile 1 (bán hàng, offline) | `mobile/sales/`, lớp lưu trữ trong `mobile/core/` |
| Mai Trinh | Mobile 2 (sổ, báo cáo, onboarding) | `mobile/ledger/`, theme và widget trong `mobile/core/` |
| Văn Thành | AI Engineer | `ai/` |

Có hai người tên Bảo. Trong issue, PR và tên nhánh luôn dùng họ tên đầy đủ hoặc tiền tố `gia-bao/`, `hoai-bao/`.

## Chạy nhanh

```bash
cp .env.example .env
docker compose up -d
```

- Mock API chạy tại http://localhost:4010 (dựng từ `api/openapi.yaml`).
- Mọi endpoint cần header `Authorization: Bearer test` khi gọi vào mock.
- Thử: `curl -H "Authorization: Bearer test" http://localhost:4010/tax/params` (không có token sẽ trả 401)
- Lưu ý: mock phục vụ đường dẫn **không có** tiền tố `/api/v1` (ví dụ `/tax/params`), còn backend thật dùng `/api/v1/tax/params`. Cấu hình `base URL` của app và test theo môi trường để chuyển giữa mock và backend thật.
- Mock trả dữ liệu mẫu lấy từ ví dụ trong hợp đồng; giá trị chỉ để minh họa định dạng, không phải số thuế thật.
- PostgreSQL chạy tại `localhost:5432` (tài khoản trong `.env`).

Chạy xong, báo Tấn Tài nếu có lỗi. Chi tiết quy tắc làm việc: xem `CONTRIBUTING.md`.

## Nguyên tắc

1. Hợp đồng trước, code sau: mọi nơi hai người nối với nhau đều đi qua `api/openapi.yaml`. Muốn đổi API thì sửa file này bằng PR và báo Ngọc Thái.
2. Một thư mục một chủ. Muốn sửa thư mục người khác: mở issue hoặc PR để chủ duyệt.
3. Tiền là số nguyên VND. Thời gian lưu UTC. Tham số thuế là cấu hình, không viết cứng trong mã.
4. Không đưa vào repo: khóa, mật khẩu, `.env` thật, dữ liệu hộ thật, ảnh hóa đơn chưa che thông tin.

## Mã yêu cầu

`FR-xxx` yêu cầu chức năng, `NFR-xxx` phi chức năng, `BR-xxx` quy tắc nghiệp vụ, `UAT-xx` kịch bản nghiệm thu, `TC-xxx` test case. Ghi mã vào tiêu đề issue và mô tả PR để truy vết về SRS.
