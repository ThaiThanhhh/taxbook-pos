# Rà soát màn hình (Gate 1 mục 6) – kết quả sau khi đối chiếu Figma với SRS/openapi

| # | Màn | Sai lệch | Cách sửa | Người | Ưu tiên |
|---|---|---|---|---|---|
| 1 | Thuế tạm tính (tổng quan) | Tính GTGT 1% và TNCN 0,5% cho cả 30.000.000 đ; màn chi tiết chia ngành nên GTGT đúng là 625.000 đ (185.000 + 350.000 + 90.000) và TNCN theo ngành 277.500 đ | Dùng kết quả từ API calculate, hiển thị theo ngành. Nhãn "tạm tính, chưa xác minh" giữ nguyên | Mai Trinh | Cao |
| 2 | Thuế (cách 1) | TNCN cách 1 chỉ tính trên doanh thu năm vượt 1 tỷ; màn không có doanh thu lũy kế | Thêm dòng "doanh thu từ đầu năm" | Mai Trinh | Cao |
| 3 | Toàn bộ | Hai màu (#005A43, #145C4B) và hai tên (TaxBook POS, ĐT13 POS) | Chốt: màu #145C4B (theme Flutter), tên app "bán là có sổ" | Mai Trinh, Gia Bảo | Trung bình |
| 4 | Thanh toán, lịch sử | Mã phiếu theo ADR-010 | Xem ADR-010 | Gia Bảo | Cao |
| 5 | Đăng nhập | "Đủ 6 số là vào" | Gọi `/auth/login`, báo lỗi 401 | Gia Bảo | Cao |
| 6 | Chọn ngành | 4 ô, chưa ánh xạ | Theo ADR-012 | Mai Trinh | Trung bình |
| 7 | Chi phí / OCR | Nút có, màn đích chưa thiết kế | Thiết kế: chụp ảnh → xem số AI đọc → sửa → lưu; luôn có bước xác nhận | Mai Trinh | Cao |
| 8 | Sao kê | Chưa có | Màn nhập CSV, danh sách khớp tự động / cần xác nhận | Mai Trinh | Trung bình |
| 9 | Hủy đơn | Chưa có | Nút hủy ở chi tiết đơn, hỏi lý do, ghi bút toán đảo (ADR-009) | Gia Bảo | Trung bình |
| 10 | Quản lý sản phẩm | Chưa có | Danh sách, thêm/sửa, chọn ngành thuế cho sản phẩm | Gia Bảo | Cao (vì cần cho bán hàng) |
| 11 | Hóa đơn | Chưa có danh sách | Danh sách hóa đơn và trạng thái | Gia Bảo | Thấp |
| 12 | Trợ lý hỏi đáp | Chưa có | Hộp chat đơn giản, hiển thị nguồn số liệu | Mai Trinh | Thấp (tuần 8+) |
| 13 | Cài đặt | Số tài khoản được nhắc nhưng chưa có màn | Màn nhập số tài khoản nhận tiền | Gia Bảo | Trung bình |

Kết luận: 4 màn cần sửa trước khi code tiếp (1, 2, 4, 5), 6 màn cần thiết kế mới. Sau khi sửa, BA rà lại và ký Gate 1 mục 6.
