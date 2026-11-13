# Danh sách màn hình cho prototype (Gate 1)
Mai Trinh và Gia Bảo dựng bản mock (Figma hoặc Flutter tĩnh); BA rà theo bảng này. Mỗi màn hình có người dùng chính và yêu cầu truy vết.

| # | Màn hình | Thư mục mobile | Chủ | Truy vết |
|---|---|---|---|---|
| 1 | Đăng nhập, chọn hộ | onboarding | Mai Trinh | FR-01 |
| 2 | Thiết lập hộ (ngành, phương pháp thuế) | onboarding | Mai Trinh | BR-08 |
| 3 | Danh sách/sửa sản phẩm | pos | Gia Bảo | FR-02 |
| 4 | Bán hàng (giỏ, tính tiền) | pos | Gia Bảo | FR-03 |
| 5 | Thanh toán (tiền mặt, CK, QR) và biên nhận tạm | payment | Gia Bảo | FR-03, FR-06 |
| 6 | Trạng thái đồng bộ | core/sync | Gia Bảo | FR-05 |
| 7 | Danh sách hóa đơn, thử lại | invoice | Gia Bảo | FR-07 |
| 8 | Sổ thu chi theo ngày | ledger | Mai Trinh | FR-09 |
| 9 | Nhập chi phí, chụp chứng từ | ledger | Mai Trinh | FR-10 |
| 10 | Nhập sao kê, đối soát | ledger | Mai Trinh | FR-11 |
| 11 | Báo cáo lãi ngày, top hàng, dòng tiền | reports | Mai Trinh | FR-15 |
| 12 | Tờ khai nháp, chốt kỳ, cảnh báo ngưỡng | tax | Mai Trinh | FR-12–14 |
| 13 | Trợ lý hỏi đáp | assistant | Mai Trinh | FR-16 |
| 14 | Hủy đơn | pos | Gia Bảo | FR-08 |

Tiêu chí rà: chữ to, thao tác ≤ 3 chạm để bán một món, trạng thái offline luôn nhìn thấy, mọi số tiền ghi đơn vị đồng, không dùng thuật ngữ thuế khó hiểu khi không cần.
