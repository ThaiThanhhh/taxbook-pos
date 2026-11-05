# Kế hoạch kiểm thử DT13 "Bán là có sổ"

Chủ: Tấn Tài (QA/DevOps) · Phiên bản v0.1 · Theo SRS v1.0 (dự thảo)

## 1. Phạm vi
- Hợp đồng API (api/openapi.yaml), đồng bộ offline, số thuế, E2E, tải, bảo mật, khả dụng.
- Không thử với dữ liệu hộ thật. Mọi dữ liệu do tools/seed sinh ra, seed cố định.

## 2. Thư mục test (khớp cột "Nơi chạy" của UAT)
| Thư mục | Nội dung |
|---|---|
| tests/e2e | UAT-01, 03 (app + backend + hóa đơn) |
| tests/acceptance | UAT-02, 05, 06, 07, 09, 11, 12, 13, 15 |
| tests/tax | UAT-10, đọc tax-test-vectors.csv và bảng giảng viên |
| tests/load | UAT-16 (NFR-02) |
| tests/contract | NFR-05, kiểm tra api/openapi.yaml |
| tools/mock-invoice-provider | UAT-04 |
| ai/tests | UAT-08, 14 (Văn Thành chủ) |

## 3. Môi trường
| Môi trường | Dùng để | Cách chạy |
|---|---|---|
| Mock | Test hợp đồng | Prism, cổng 4010, Authorization: Bearer test |
| Local | Backend + PostgreSQL thật | docker compose (bổ sung tuần 3) |
| Demo | Diễn tập nghiệm thu | (bổ sung tuần 4) |

## 4. Tiêu chí nghiệm thu (theo đề)
- 50 hộ, 5 nhóm ngành, 20.000 giao dịch.
- 100% hóa đơn đồng bộ đúng sau kịch bản mất mạng (80 đơn, đúng thứ tự, không trùng số).
- Số thuế khớp bảng giảng viên cho mọi nhóm ngành, sai lệch 0 đồng.
- 5 chủ hộ thật hoàn thành đơn đầu dưới 3 phút, không cần hướng dẫn.

## 5. Ma trận truy vết
| UAT | Tình huống | Yêu cầu | Test case | Nơi chạy |
|---|---|---|---|---|
| 01 | Bán offline 20 đơn rồi đồng bộ | FR-04, 05 | TC-E2E-001 | tests/e2e |
| 02 | Gửi lại gói đồng bộ, không trùng | FR-05, NFR-03 | TC-SYNC-001 | tests/acceptance |
| 03 | Đơn offline nhận số hóa đơn chính thức | FR-06, 07 | TC-E2E-002 | tests/e2e |
| 04 | Nhà cung cấp hóa đơn lỗi, outbox thử lại | FR-07 | TC-INV-001 | tools/mock-invoice-provider |
| 05 | Hủy đơn, sổ cái cân bằng | FR-08, BR-02 | TC-LED-001 | tests/acceptance |
| 06 | Ngày ghi sổ đúng khi đồng bộ trễ | FR-09 | TC-LED-002 | tests/acceptance |
| 07 | Nhập chi phí tay, lãi đổi đúng | FR-10 | TC-LED-003 | tests/acceptance |
| 08 | OCR chi phí, người dùng xác nhận | FR-10 | TC-AI-001 | ai/tests |
| 09 | Đối soát sao kê >= 80% | FR-11 | TC-LED-004 | tests/acceptance |
| 10 | Tờ khai nháp khớp bảng giảng viên | FR-12, 13 | TC-TAX-001..006 | tests/tax |
| 11 | Đổi tham số thuế, kỳ cũ không đổi | FR-17, BR-04 | TC-TAX-007 | tests/acceptance |
| 12 | Chốt kỳ rồi sửa, PERIOD_LOCKED | FR-13, BR-03 | TC-TAX-008 | tests/acceptance |
| 13 | Cảnh báo ngưỡng 80% | FR-14 | TC-TAX-009 | tests/acceptance |
| 14 | Hỏi AI "hôm nay lãi bao nhiêu" | FR-16 | TC-AI-002 | ai/tests |
| 15 | Hộ A không thấy dữ liệu hộ B | NFR-04 | TC-SEC-001 | tests/acceptance |
| 16 | Tải: 100 đơn đồng bộ dưới 30 giây | NFR-02 | TC-LOAD-001 | tests/load |
| – | ErrorEnvelope thống nhất, khớp hợp đồng | NFR-05 | TC-API-001 | tests/contract |

## 6. Test thuế
- Nguồn kỳ vọng: tax-test-vectors.csv (TV-01..06) rồi bảng của giảng viên.
- Tiền là số nguyên VND, so sánh bằng, không dung sai.
- Tính độc lập: tests/tax có hàm tính riêng đọc config/tax/ để đối chiếu với backend.
- Biên bắt buộc: doanh thu đúng 1 tỷ (TV-04) và 1 tỷ + 1 đồng (TV-05).

## 7. Điều kiện hợp nhất PR
- CI xanh và ít nhất 1 review.

## 8. Việc chờ chốt
- Quy tắc làm tròn tiền thuế (BR mới).
- 5 nhóm ngành của dữ liệu giả lập (params có 6 nhóm).
- Nhóm ngành của quán cơm, sửa xe.
- Mốc biên: "từ 1 tỷ trở xuống" hay "trên 1 tỷ".
- Bảng đối chiếu của giảng viên.
- Tham số thuế đang DRAFT_UNVERIFIED.