# Báo cáo kiểm thử DT13 "Bán là có sổ" (Tuần 1 đến 2)

Người lập: Tấn Tài (QA/DevOps) · Cập nhật: 18/11/2026 · Theo TEST_PLAN v0.1

## 1. Tóm tắt
- Đã chạy 15 test tự động, **đạt 15/15**, chưa có lỗi nào.
- Toàn bộ test hiện chạy trên **hàm tính độc lập, máy chủ giả và mock**, vì backend chưa sẵn sàng để chạy thật.
- Dữ liệu giả lập đạt yêu cầu đề: 50 hộ, 5 nhóm ngành, 20.000 giao dịch.
- Chưa merge được PR nào vào main (đang chờ review).

## 2. Kết quả chạy
| Nhóm test | Mã TC | Số test | Kết quả | Chạy trên | Lệnh chạy lại |
|---|---|---|---|---|---|
| Số thuế | TC-TAX-001..006 | 6 | Đạt 6/6 | hàm tính độc lập | python tests/tax/test_tax_vectors.py |
| Đồng bộ offline | TC-SYNC-001..006 | 6 | Đạt 6/6 | máy chủ giả | python tests/sync/test_dong_bo.py |
| Hợp đồng API | TC-API-002..004 | 3 | Đạt 3/3 | mock Prism cổng 4010 | python tests/contract/test_hop_dong_mock.py |

Kịch bản chính của đề (quán cơm mất mạng, bán 80 đơn): **TC-SYNC-002 đạt**. Đủ 80 đơn, số hóa đơn liên tục HD0000001 đến HD0000080, đúng thứ tự local_seq, gửi lại lô thì không trùng.

## 3. Dữ liệu giả lập
| Hạng mục | Số lượng |
|---|---|
| Hộ kinh doanh | 50 |
| Giao dịch | 20.000 |
| Dòng sao kê ngân hàng giả (có khoảng 5% dòng nhiễu) | 8.314 |
| Đơn kịch bản mất mạng | 80 |

Sinh bằng tools/seed/sinh_du_lieu.py, SEED=2026 (cố định). Không dùng dữ liệu hộ thật.

## 4. Vấn đề phát hiện (không phải lỗi của test)
| # | Vấn đề | Tác động | Cần ai xử lý |
|---|---|---|---|
| 1 | tax-params.v0.json và v1-draft.json còn nhóm OTHER, trong khi nhóm đã chốt bỏ OTHER (5 nhóm) | Test và dữ liệu giả có thể lệch với backend | Thái |
| 2 | tax-rules.md ghi ánh xạ ngành cho 3 hộ khảo sát là "phỏng đoán, cần xác nhận" | Nhóm ngành của quán cơm và sửa xe chưa chắc | Thái |
| 3 | Chưa chốt quy tắc làm tròn tiền thuế | Test thuế đang dùng chia lấy phần nguyên, có thể lệch 1 đồng | Thái |
| 4 | Chưa chốt mốc biên đúng 1 tỷ và 3 tỷ | TC-TAX-004, 005 dựa theo bảng vector hiện có | Thái |
| 5 | Tham số thuế đang DRAFT_UNVERIFIED | Chưa dùng làm bảng đối chiếu chính thức | Thái |

## 5. Rủi ro và việc chưa làm
- Chưa có test chạy với backend thật (cần API /sync/sales và /tax/... chạy được, đổi biến BASE_URL).
- Chưa chạy Docker compose, chưa có môi trường demo (infra/).
- Chưa làm: quét bảo mật, test tải (UAT-16), test đọc bảng đối chiếu của giảng viên, test tờ khai.
- Main chưa bật bảo vệ nhánh.

## 6. Kế hoạch tuần tới
1. Chạy Docker, dựng môi trường local (infra/).
2. Test đọc bảng CSV vector thuế của Thái và thêm test cho nhóm RENTAL_AGENT, DIGITAL_CONTENT khi có công thức.
3. Khi backend sẵn sàng: chạy lại TC-SYNC và TC-API bằng BASE_URL trỏ vào backend.
4. Quét bảo mật cơ bản (gitleaks, npm audit, pip-audit).

## 7. Trạng thái PR
| PR | Nội dung | Trạng thái |
|---|---|---|
| #13 | Kế hoạch kiểm thử | Chờ review |
| #16 | .env.example | Chờ review |
| #17 | Test thuế | Chờ review |
| #20 | Bộ sinh dữ liệu giả | Chờ review |
| #28 | CI (GitHub Actions) | Chờ review, CI xanh |
| sync-test | Test đồng bộ | Chờ review |
| contract-test | BASE_URL và test hợp đồng | Chờ review |