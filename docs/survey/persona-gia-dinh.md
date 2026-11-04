# Câu trả lời GIẢ ĐỊNH cho bộ khảo sát (persona mẫu)

> **ĐÂY KHÔNG PHẢI DỮ LIỆU KHẢO SÁT THẬT.** Ba persona dưới đây được soạn dựa trên bối cảnh đề DT13 để nhóm có đầu vào tạm cho thiết kế và kiểm thử trước khi gặp hộ thật. Không trích dẫn như kết quả khảo sát trong báo cáo; khi nộp phải ghi "persona giả định". Thay bằng biên bản thật khi có.

Số liệu doanh thu khớp với `docs/test-plan/tax-test-vectors.csv` (tạp hóa 2,4 tỷ, quán cơm 1,8 tỷ, sửa xe 1,2 tỷ).

## Hồ sơ persona
| Persona | Ngành | Doanh thu/năm | Nhóm thuế tạm | Điểm đau lớn nhất |
|---|---|---|---|---|
| Cô Lan | Tạp hóa | ~2,4 tỷ | GOODS_DISTRIBUTION | Kiểm kho, gom chứng từ, tính thuế |
| Anh Hùng | Quán cơm | ~1,8 tỷ | PRODUCTION_TRANSPORT | Tốc độ giờ cao điểm, không có hóa đơn đầu vào |
| Chú Tư | Sửa xe | ~1,2 tỷ | SERVICE (tách phụ tùng) | Máy tay dính dầu, chưa biết nghĩa vụ thuế |

## A. Câu hỏi chung
**A1**
- Tạp hóa (cô Lan): Bán 12 năm, 2 người (vợ chồng), vợ ghi tiền, chồng nhập hàng.
- Quán cơm (anh Hùng): Mở 6 năm, 5 người (2 phụ bếp, 1 bưng bê, vợ thu ngân); vợ giữ tiền.
- Sửa xe (chú Tư): Mở 15 năm, chú và 2 thợ; chú nhận xe và thu tiền.

**A2**
- Tạp hóa (cô Lan): Khoảng 150–200 lượt khách/ngày; cao điểm 6–8h sáng và 17–19h.
- Quán cơm (anh Hùng): Khoảng 250 suất/ngày; cao điểm 11h30–13h, rất đông.
- Sửa xe (chú Tư): Khoảng 15–25 xe/ngày; cao điểm sáng thứ Hai và cuối tuần.

**A3**
- Tạp hóa (cô Lan): Khoảng 2,4 tỷ/năm (nhóm 1–3 tỷ); mùa Tết cao gấp rưỡi.
- Quán cơm (anh Hùng): Khoảng 1,8 tỷ/năm; ổn định, hơi giảm mùa mưa.
- Sửa xe (chú Tư): Khoảng 1,2 tỷ/năm; cao điểm mùa mưa.

**A4**
- Tạp hóa (cô Lan): Sổ giấy, có Excel cuối tháng do con gái nhập.
- Quán cơm (anh Hùng): Sổ giấy + ghi chú điện thoại; cuối ngày cộng tiền.
- Sửa xe (chú Tư): Cuốn sổ tay ghi tên khách, biển số, tiền; không có Excel.

**A5**
- Tạp hóa (cô Lan): Có nghe S1a/S2a nhưng chưa dùng đúng; kế toán thuê ngoài lo.
- Quán cơm (anh Hùng): Chưa dùng mẫu nào; chưa ai hướng dẫn.
- Sửa xe (chú Tư): Chưa biết mẫu; chi cục thuế có gọi nhưng chú chưa đi.

**A6**
- Tạp hóa (cô Lan): Kế toán thuê ngoài, khai quý, mất vài ngày gom hóa đơn; sợ sai tỷ lệ.
- Quán cơm (anh Hùng): Vợ tự khai theo năm; mỗi lần mất 2 ngày, không chắc đúng.
- Sửa xe (chú Tư): Chưa nộp thuế riêng trước đây (khoán); đang lo thay đổi chính sách.

**A7**
- Tạp hóa (cô Lan): Biết sắp phải dùng hóa đơn điện tử khi vượt 1 tỷ; chưa đăng ký.
- Quán cơm (anh Hùng): Nghe nói nhưng chưa rõ mốc; chưa dùng.
- Sửa xe (chú Tư): Chưa biết mốc; thấy rắc rối.

**A8**
- Tạp hóa (cô Lan): Tiền mặt 70%, chuyển khoản/QR 30%; chưa đối chiếu sao kê.
- Quán cơm (anh Hùng): Tiền mặt 60%, QR 40%; có ứng dụng ngân hàng, hiếm khi đối chiếu.
- Sửa xe (chú Tư): Tiền mặt 50%, chuyển khoản 50% (khách công ty); đối chiếu bằng cách nhớ.

**A9**
- Tạp hóa (cô Lan): Mất mạng thì ghi tạm giấy rồi nhập lại; từng ghi nhầm vài lần.
- Quán cơm (anh Hùng): Mạng yếu giờ cao điểm; ghi giấy, đôi khi quên món.
- Sửa xe (chú Tư): Tiệm hay yếu sóng; ghi tay, ít khi mất đơn.

**A10**
- Tạp hóa (cô Lan): Giữ phiếu giao hàng từ 3 nhà cung cấp lớn; chợ nhỏ không có chứng từ.
- Quán cơm (anh Hùng): Mua chợ hằng ngày gần như không có hóa đơn.
- Sửa xe (chú Tư): Phụ tùng lớn có hóa đơn; đồ lặt vặt không.

**A11**
- Tạp hóa (cô Lan): Trả hàng, hết hạn vài lần/tháng; ghi chú trong sổ.
- Quán cơm (anh Hùng): Hủy món hiếm, giảm giá cho khách quen.
- Sửa xe (chú Tư): Hủy ít; giảm công cho khách quen.

**A12**
- Tạp hóa (cô Lan): Điện thoại Android tầm trung, dùng Zalo, ngân hàng; chưa dùng app bán hàng.
- Quán cơm (anh Hùng): Điện thoại Android cũ, màn hình nhỏ; quen Zalo.
- Sửa xe (chú Tư): Điện thoại Android cũ, tay hay dính dầu; cần nút to.

**A13**
- Tạp hóa (cô Lan): Muốn tự tính thuế, báo hết hàng; sợ nhập sai tốn thời gian.
- Quán cơm (anh Hùng): Muốn tính tiền nhanh giờ cao điểm; sợ máy treo.
- Sửa xe (chú Tư): Muốn lưu lịch sử sửa của từng xe; sợ khó dùng.

**A14**
- Tạp hóa (cô Lan): Thấy hữu ích nếu trả lời ngắn, chính xác.
- Quán cơm (anh Hùng): Thích, cần nói được bằng giọng nói.
- Sửa xe (chú Tư): Không cần lắm; nếu có thì để tra công nợ.

## B. Quán cơm (anh Hùng)
- **B1** Ăn tại chỗ 70%, mang đi 20%, giao qua app 10%.
- **B2** Gọi món theo thực đơn khoảng 25 món; đổi 3–4 món mỗi ngày.
- **B3** Giá ổn định, đổi khi giá thịt lên; có giảm cho khách quen.
- **B4** Đa số trả sau khi ăn; vài khách công ty ghi sổ cuối tháng.
- **B5** Mua chợ mỗi sáng, không hóa đơn; chỉ ghi tổng số tiền.
- **B6** Mặt bằng 25 triệu/tháng, điện nước 12 triệu, nhân công 45 triệu; mặt bằng và lương chuyển khoản.
- **B7** Hao hụt khoảng 5%; không quản lý tồn nguyên liệu.
- **B8** Hai người gọi món cùng lúc, dùng 1–2 điện thoại.
- **B9** Khách công ty đặt tiệc thỉnh thoảng yêu cầu hóa đơn.

## C. Tạp hóa (cô Lan)
- **C1** Khoảng 800 mặt hàng; khoảng 60% có mã vạch, quét được bằng camera điện thoại.
- **C2** Giá nhập đổi hằng tuần; giá bán đổi theo nhà cung cấp; lãi 8–25% tùy mặt hàng.
- **C3** Kiểm kho 1 lần/tháng bằng mắt; hết hàng mới biết.
- **C4** Nhập từ 12 nhà cung cấp; 4 nhà cho phiếu giao hàng đều.
- **C5** Có bán chịu cho 15 khách quen; ghi sổ tay.
- **C6** Có bán sỉ cho quán nhỏ, giá thấp hơn 5–8%.
- **C7** Có bán thuốc lá, bia và nạp thẻ điện thoại (doanh thu nhỏ).
- **C8** Hàng hết hạn bỏ hoặc trả nhà cung cấp; không ghi đầy đủ.

## D. Sửa xe (chú Tư)
- **D1** Khoảng 70% công sửa, 30% bán phụ tùng/nhớt/lốp.
- **D2** Có phiếu nhận xe viết tay; báo giá bằng miệng.
- **D3** Phụ tùng mua ở đại lý, có hóa đơn một phần; mua khi có khách.
- **D4** Thỉnh thoảng đặt cọc xe lớn; lấy xe sau 1–3 ngày.
- **D5** Sửa 3–4 xe cùng lúc; ghi theo biển số; bảo hành 1 tháng.
- **D6** Thuê 2 thợ, trả theo tháng cộng thưởng.
- **D7** Khách công ty/bảo hiểm có yêu cầu hóa đơn vài lần/tháng.
- **D8** Hay mất sóng; điện thoại hay bẩn, dầu nhớt.

## E. Câu cuối buổi (giả định)
- Màn hình mẫu: cả ba cần chữ to và nút to; không hiểu từ "đồng bộ", đổi thành "đã lưu lên máy chủ".
- Muốn thêm: nhắc hạn nộp thuế (cô Lan), nói để gọi món (anh Hùng), lịch sử sửa theo biển số (chú Tư).
- Đồng ý thử bản demo tuần 9–10.

## Điều rút ra cho thiết kế (đều là giả thuyết cần kiểm chứng với hộ thật)
| Phát hiện giả định | Ảnh hưởng | Truy vết |
|---|---|---|
| Cả ba hay mất mạng/yếu sóng | Offline-first là bắt buộc | FR-04, UAT-01 |
| Chi phí mua chợ/đồ lặt vặt thiếu chứng từ | Cần cảnh báo chi phí không đủ điều kiện trừ; chi phí ≥ 5 triệu phải chuyển khoản | FR-10, tax-rules mục 4 |
| Cả ba chưa rõ mốc hóa đơn điện tử | Cảnh báo gần ngưỡng 1 tỷ | FR-14, UAT-13 |
| Thanh toán trộn tiền mặt/QR | Hỗ trợ nhiều phương thức; đối soát sao kê | FR-03, FR-11 |
| Tạp hóa có bán chịu, quán cơm ghi sổ công ty | Công nợ là nhu cầu, hiện chưa có trong SRS | **Đề xuất thêm FR (Could)** |
| Sửa xe cần lưu theo biển số, bảo hành | Chưa có trong SRS | **Đề xuất thêm FR (Could)** |
| Sửa xe bán phụ tùng kèm công | Doanh thu tách hai nhóm thuế | BR-08 |
| Quán cơm nhiều người gọi món cùng lúc | Nhiều thiết bị đồng bộ cùng hộ | FR-05, device_id |
| Máy cũ, tay dính dầu, chữ nhỏ | Nút to, thao tác ≤ 3 chạm | NFR-06, screens.md |
