# Việc tuần 3–4 theo người (cập nhật 13/11 theo tình hình repo)

Nguyên tắc: không bắt đầu việc mới trước khi việc đang dở được merge vào main (ADR-015).

| Người | Việc ưu tiên (theo thứ tự) | Xong khi |
|---|---|---|
| Quang Dũng | 1) Đăng ký SalesModule vào AppModule, thêm controller `/sales`, `/sync/sales`; 2) Auth `/auth/login` (ADR-011) và Catalog; 3) thống nhất thứ tự dựng CSDL với Hoài Bảo (ADR-014) | PR vào main; gọi được bằng curl; test xanh |
| Hoài Bảo | 1) Mở rộng bộ nạp tham số cho v1.1 (6 ngành, khung 17%, 20%); 2) `POST /tax/periods/{id}/calculate` cho 3 ca mẫu (`tax-test-vectors.csv`); 3) tự khớp sao kê ≥80% | Test chạy với 6 ca của Tài |
| Gia Bảo | 1) Merge nhánh local-database và cart-seed-auth; 2) mã phiếu theo ADR-010; 3) nối màn bán hàng với mock rồi API thật; 4) màn quản lý sản phẩm | App tạo đơn offline, đồng bộ lên mock |
| Mai Trinh | 1) Sửa màn thuế (screen-review #1, #2); 2) bỏ hằng số trong tax engine, gọi API (ADR-013); 3) màn chi phí/OCR; 4) đổi màu theo theme | Màn thuế khớp 625.000/277.500 với dữ liệu mẫu |
| Văn Thành | 1) Merge `feature/ai-service`; 2) đổi đường dẫn sang `/ai/expense-ocr`, `/ai/ask`; 3) sửa tách số tiền, thử ảnh hóa đơn có dấu; 4) trả tiền dạng số nguyên | 5 ảnh hóa đơn mẫu đọc đúng tổng |
| Tấn Tài | 1) CI lint openapi; 2) Prism mock; 3) thứ tự dựng CSDL trong CI; 4) nối test thuế vào CI; 5) bật bảo vệ main | CI xanh trên main |
| Ngọc Thái | 1) họp chốt ADR và Gate 1; 2) đi khảo sát 3 hộ; 3) theo dõi merge | Gate 1 ký xong đầu tuần 4 |

Họp: thứ Hai (kế hoạch, chốt ADR) và thứ Năm (demo ngắn, mỗi người chạy phần của mình).
