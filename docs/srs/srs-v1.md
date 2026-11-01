# SRS v1.0 – DT13 "bán là có sổ"
Tác giả: Ngọc Thái · Tuần 1 · Trạng thái: Dự thảo – mục [CHỐT] chờ giảng viên.

## 1. Giới thiệu
Mục đích: đặc tả yêu cầu hệ thống quản lý bán hàng offline-first và tự tính thuế cho hộ kinh doanh. Đối tượng đọc: cả nhóm, giảng viên. Tham chiếu: đề DT13, api/openapi.yaml, docs/erd, config/tax/tax-params.v1-draft.json.

## 2. Tác nhân
Chủ hộ (Owner), Thu ngân (Cashier), Quản trị (Admin), Hệ thống hóa đơn (sandbox), Dịch vụ AI.

## 3. Yêu cầu chức năng
| ID | Yêu cầu | MoSCoW | Truy vết |
|---|---|---|---|
| FR-01 | Đăng nhập/làm mới token | Must | US-01 |
| FR-02 | Quản lý sản phẩm, giá, tồn | Must | US-02, US-21 |
| FR-03 | Tạo đơn bán nhiều dòng, nhiều hình thức thanh toán | Must | US-03 |
| FR-04 | Hoạt động đầy đủ khi offline, hàng đợi đồng bộ | Must | US-04 |
| FR-05 | Đồng bộ idempotent theo client_op_id; thứ tự theo device_id+local_seq | Must | US-05 |
| FR-06 | Mã tạm TMP-<device>-<seq>; số chính thức do server cấp | Must | US-03,US-07 |
| FR-07 | Xuất hóa đơn điện tử sandbox, outbox thử lại | Must | US-07,US-08 |
| FR-08 | Hủy đơn bằng bút toán đảo | Must | US-09 |
| FR-09 | Sổ cái tự sinh từ đơn/chi phí; ngày ghi sổ = client_created_at | Must | US-10 |
| FR-10 | Nhập chi phí; OCR chứng từ (AI) | Must/Could | US-11,US-12 |
| FR-11 | Nhập sao kê CSV, tự đối soát | Should | US-13 |
| FR-12 | Tính thuế GTGT/TNCN theo tham số phiên bản | Must | US-14,US-16 |
| FR-13 | Tờ khai nháp, chốt kỳ | Must | US-14,US-17 |
| FR-14 | Cảnh báo gần ngưỡng, nhắc hạn | Should/Could | US-15,US-19 |
| FR-15 | Báo cáo lãi ngày, top hàng, dòng tiền | Should | US-18 |
| FR-16 | Hỏi đáp AI về số liệu | Should | US-20 |
| FR-17 | Quản trị tham số thuế (version) | Must | US-16 |
| FR-18 | Nhật ký kiểm toán thao tác nhạy cảm | Should | – |

## 4. Quy tắc nghiệp vụ
- BR-01 Tiền là số nguyên VND; thời gian UTC; khóa chính UUID.
- BR-02 Đơn đã đồng bộ không bị xóa, chỉ đảo.
- BR-03 Kỳ đã chốt không cho sửa dữ liệu (PERIOD_LOCKED).
- BR-04 Tham số thuế gắn version vào kỳ; đổi luật không đổi kỳ cũ.
- BR-05 [CHỐT] GTGT = doanh thu × tỷ lệ ngành (toàn bộ doanh thu); TNCN theo phương pháp chọn (xem v1-draft).
- BR-06 [CHỐT] Doanh thu ≤ 1 tỷ/năm: không chịu GTGT/TNCN; >1 tỷ: hóa đơn điện tử bắt buộc.
- BR-07 [CHỐT] Kỳ kê khai (quý/năm) theo giảng viên.

## 5. Yêu cầu phi chức năng
| ID | Yêu cầu | Đo |
|---|---|---|
| NFR-01 | Tạo đơn offline < 1 giây | thử trên máy thật |
| NFR-02 | Đồng bộ 100 đơn < 30 giây | test tải |
| NFR-03 | Không mất/không trùng đơn khi lặp gửi | test idempotent |
| NFR-04 | Mật khẩu băm, HTTPS, phân quyền theo hộ | review |
| NFR-05 | API trả ErrorEnvelope thống nhất | contract test |
| NFR-06 | Giao diện tiếng Việt, dễ dùng với người ít công nghệ | UAT |
| NFR-07 | Test tự động chạy trong CI | pipeline |

## 6. Ràng buộc & giả định
Stack theo đề xuất, hóa đơn dùng sandbox/mock, không nộp thuế thật. Giả định: quy định thuế như config/tax/tax-params.v1-draft.json (chưa xác minh gốc).

## 7. Nghiệm thu (UAT)
| UAT | Tình huống | Truy vết |
|---|---|---|
| 01 | Bán offline 20 đơn rồi đồng bộ, đủ 20 đơn | FR-04,05 |
| 02 | Gửi lại gói đồng bộ, không trùng | FR-05 |
| 03 | Đơn offline nhận số hóa đơn chính thức sau sync | FR-06,07 |
| 04 | Nhà cung cấp hóa đơn lỗi, outbox thử lại thành công | FR-07 |
| 05 | Hủy đơn, sổ cái cân bằng | FR-08 |
| 06 | Ngày ghi sổ đúng khi đồng bộ trễ | FR-09 |
| 07 | Nhập chi phí tay, lãi đổi đúng | FR-10 |
| 08 | OCR chi phí, người dùng xác nhận | FR-10 |
| 09 | Đối soát sao kê ≥80% | FR-11 |
| 10 | Tờ khai nháp khớp bảng giảng viên | FR-12,13 |
| 11 | Đổi tham số thuế, kỳ cũ không đổi | FR-17,BR-04 |
| 12 | Chốt kỳ rồi sửa → PERIOD_LOCKED | FR-13 |
| 13 | Cảnh báo ngưỡng 80% | FR-14 |
| 14 | Hỏi AI "hôm nay lãi bao nhiêu" | FR-16 |
| 15 | Phân quyền: hộ A không thấy dữ liệu hộ B | NFR-04 |

## 8. Lịch sử thay đổi

