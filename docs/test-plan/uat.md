# Kế hoạch nghiệm thu (UAT) – Ngọc Thái viết, Tấn Tài tự động hóa
Kịch bản chạy tự động đặt ở `tests/acceptance/`; E2E ở `tests/e2e/`; tải ở `tests/load/`; dữ liệu mẫu ở `tools/seed/`; hóa đơn giả ở `tools/mock-invoice-provider/`.

| UAT | Tình huống | Truy vết SRS | Nơi chạy |
|---|---|---|---|
| 01 | Bán offline 20 đơn rồi đồng bộ, đủ 20 đơn | FR-04, FR-05 | tests/e2e |
| 02 | Gửi lại gói đồng bộ, không trùng | FR-05 | tests/acceptance |
| 03 | Đơn offline nhận số hóa đơn chính thức sau sync | FR-06, FR-07 | tests/e2e |
| 04 | Nhà cung cấp hóa đơn lỗi, outbox thử lại | FR-07 | tools/mock-invoice-provider |
| 05 | Hủy đơn, sổ cái cân bằng | FR-08 | tests/acceptance |
| 06 | Ngày ghi sổ đúng khi đồng bộ trễ | FR-09 | tests/acceptance |
| 07 | Nhập chi phí tay, lãi đổi đúng | FR-10 | tests/acceptance |
| 08 | OCR chi phí, người dùng xác nhận | FR-10 | ai/tests |
| 09 | Đối soát sao kê ≥ 80% | FR-11 | tests/acceptance |
| 10 | Tờ khai nháp khớp bảng giảng viên | FR-12, FR-13 | tax-test-vectors.csv |
| 11 | Đổi tham số thuế, kỳ cũ không đổi | FR-17, BR-04 | tests/acceptance |
| 12 | Chốt kỳ rồi sửa → PERIOD_LOCKED | FR-13 | tests/acceptance |
| 13 | Cảnh báo ngưỡng 80% | FR-14 | tests/acceptance |
| 14 | Hỏi AI "hôm nay lãi bao nhiêu" | FR-16 | ai/tests |
| 15 | Hộ A không thấy dữ liệu hộ B | NFR-04 | tests/acceptance |
| 16 | Tải: 100 đơn đồng bộ < 30 giây | NFR-02 | tests/load |


