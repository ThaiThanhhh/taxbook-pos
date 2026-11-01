# User stories & tiêu chí chấp nhận (Given/When/Then rút gọn)

Trạng thái: v1 – chờ giảng viên chốt mục [CHỐT]. Bản đầy đủ: backlog.csv.

## US-01 – Auth (Must)
Là **chủ hộ**, tôi muốn **đăng nhập và duy trì phiên** để **dùng app an toàn**.
- Chấp nhận: Đăng nhập đúng → token; sai → 401; refresh hoạt động
- Chủ: Dũng/Gia Bảo · Tuần 3

## US-02 – Sản phẩm (Must)
Là **chủ hộ**, tôi muốn **thêm/sửa/ẩn sản phẩm và giá** để **bán đúng hàng**.
- Chấp nhận: CRUD offline, đồng bộ khi có mạng
- Chủ: Dũng/Gia Bảo · Tuần 3

## US-03 – Bán hàng (Must)
Là **thu ngân**, tôi muốn **tạo đơn nhiều dòng hàng và thu tiền** để **hoàn tất bán**.
- Chấp nhận: Tổng tiền đúng, lưu SQLite, có mã TMP
- Chủ: Gia Bảo · Tuần 4

## US-04 – Bán hàng (Must)
Là **thu ngân**, tôi muốn **bán được khi mất mạng** để **không gián đoạn**.
- Chấp nhận: Offline tạo ≥20 đơn, không lỗi
- Chủ: Gia Bảo · Tuần 4

## US-05 – Sync (Must)
Là **hệ thống**, tôi muốn **đồng bộ đơn bằng client_op_id** để **không mất/không trùng**.
- Chấp nhận: Gửi lại 2 lần → 1 đơn
- Chủ: Dũng · Tuần 5

## US-06 – Sync (Should)
Là **thu ngân**, tôi muốn **thấy trạng thái đồng bộ** để **biết đơn nào chưa lên**.
- Chấp nhận: Badge pending/synced/failed
- Chủ: Gia Bảo · Tuần 5

## US-07 – Hóa đơn (Must)
Là **chủ hộ**, tôi muốn **xuất hóa đơn điện tử cho đơn** để **tuân thủ khi >1 tỷ**.
- Chấp nhận: Sandbox/mock trả số hóa đơn chính thức
- Chủ: Dũng · Tuần 5

## US-08 – Hóa đơn (Should)
Là **chủ hộ**, tôi muốn **hóa đơn tự thử lại khi lỗi nhà cung cấp** để **không mất hóa đơn**.
- Chấp nhận: Outbox retry, trạng thái rõ
- Chủ: Dũng · Tuần 6

## US-09 – Hủy đơn (Must)
Là **chủ hộ**, tôi muốn **hủy đơn bằng bút toán đảo** để **giữ vết kiểm toán**.
- Chấp nhận: Reversal; sổ cái cân bằng
- Chủ: Dũng/Hoài Bảo · Tuần 6

## US-10 – Sổ cái (Must)
Là **chủ hộ**, tôi muốn **xem sổ thu chi theo ngày** để **biết tiền vào ra**.
- Chấp nhận: Khớp tổng đơn đã đồng bộ
- Chủ: Hoài Bảo/Mai Trinh · Tuần 5

## US-11 – Chi phí (Must)
Là **chủ hộ**, tôi muốn **nhập chi phí thủ công** để **tính lãi đúng**.
- Chấp nhận: Chi phí vào sổ cái
- Chủ: Mai Trinh · Tuần 6

## US-12 – Chi phí (Could)
Là **chủ hộ**, tôi muốn **chụp hóa đơn để AI đọc chi phí** để **đỡ nhập tay**.
- Chấp nhận: OCR trả draft, người dùng xác nhận
- Chủ: Thành/Mai Trinh · Tuần 8

## US-13 – Sao kê (Should)
Là **chủ hộ**, tôi muốn **nhập sao kê CSV và đối soát** để **phát hiện thiếu sót**.
- Chấp nhận: Tự khớp ≥80% dòng mẫu
- Chủ: Hoài Bảo/Mai Trinh · Tuần 7

## US-14 – Thuế (Must)
Là **chủ hộ**, tôi muốn **xem tờ khai thuế nháp theo kỳ** để **biết số phải nộp**.
- Chấp nhận: Khớp bảng giảng viên
- Chủ: Hoài Bảo · Tuần 8

## US-15 – Thuế (Should)
Là **chủ hộ**, tôi muốn **hệ thống cảnh báo khi gần ngưỡng 1 tỷ** để **kịp xuất hóa đơn**.
- Chấp nhận: Cảnh báo ở 80%/100%
- Chủ: Hoài Bảo/Mai Trinh · Tuần 8

## US-16 – Thuế (Must)
Là **quản trị**, tôi muốn **cập nhật bộ tham số thuế có phiên bản** để **đổi luật không sửa code**.
- Chấp nhận: Tạo version mới, kỳ cũ giữ version cũ
- Chủ: Hoài Bảo · Tuần 7

## US-17 – Thuế (Must)
Là **chủ hộ**, tôi muốn **chốt kỳ thuế** để **dữ liệu không bị sửa**.
- Chấp nhận: Sau chốt: PERIOD_LOCKED
- Chủ: Hoài Bảo · Tuần 9

## US-18 – Báo cáo (Should)
Là **chủ hộ**, tôi muốn **xem lãi hằng ngày, top hàng bán chạy, dòng tiền** để **ra quyết định**.
- Chấp nhận: Số liệu khớp sổ cái
- Chủ: Hoài Bảo/Mai Trinh · Tuần 8

## US-19 – Nhắc (Could)
Là **chủ hộ**, tôi muốn **nhận nhắc hạn kê khai** để **không trễ hạn**.
- Chấp nhận: Nhắc trước hạn N ngày
- Chủ: Mai Trinh · Tuần 9

## US-20 – AI (Should)
Là **chủ hộ**, tôi muốn **hỏi bằng tiếng Việt 'hôm nay lãi bao nhiêu'** để **tra nhanh**.
- Chấp nhận: Trả lời đúng số liệu, có nguồn
- Chủ: Thành · Tuần 8

## US-21 – Kho (Should)
Là **chủ hộ**, tôi muốn **thấy tồn kho giảm khi bán** để **tránh hết hàng**.
- Chấp nhận: Tồn giảm theo đơn
- Chủ: Dũng/Gia Bảo · Tuần 6

## US-22 – Phi chức năng (Must)
Là **nhóm**, tôi muốn **CI chạy lint, test, mock** để **chất lượng ổn**.
- Chấp nhận: PR fail nếu lint/test đỏ
- Chủ: Tài · Tuần 2

