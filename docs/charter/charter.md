# Project Charter – DT13 "bán là có sổ"
Phiên bản 1.0 – Tuần 1 – Chủ trì: Ngọc Thái (SV01, BA/Lead)

## 1. Bối cảnh & vấn đề
Hộ kinh doanh nhỏ bán hàng nhưng ghi sổ thủ công, khó tính thuế khi chính sách thay đổi (ngưỡng 1 tỷ, sổ S1a–S2e, hóa đơn điện tử bắt buộc >1 tỷ). Mất mạng tại điểm bán làm gián đoạn bán hàng.

## 2. Mục tiêu
1. Bán hàng offline-first, đồng bộ không mất/không trùng đơn.
2. Tự động ghi sổ và tính thuế GTGT/TNCN theo tham số cấu hình được.
3. Xuất hóa đơn điện tử (sandbox/mock), đối soát sao kê.
4. Trợ lý AI hỏi đáp số liệu và đọc chứng từ chi phí.

## 3. Phạm vi
Trong: mobile POS, sync, sổ thu chi, tính thuế nháp, hóa đơn sandbox, báo cáo, AI cơ bản, admin tham số thuế.
Ngoài: nộp thuế thật lên cơ quan thuế, thanh toán thật, ứng dụng iOS phát hành store.

## 4. Thành viên & vai trò
| SV | Tên | Vai trò | Sở hữu |
|---|---|---|---|
| 01 | Ngọc Thái | BA/Lead | docs/, api/, config/tax/ |
| 02 | Quang Dũng | Backend Sales & Invoice | backend/sales, common |
| 03 | Hoài Bảo | Backend Ledger & Tax | backend/ledger, tax |
| 04 | Gia Bảo | Mobile 1 | mobile/sales, core storage |
| 05 | Mai Trinh | Mobile 2 | mobile/ledger, theme |
| 06 | Văn Thành | AI | ai/ |
| 07 | Tấn Tài | QA/DevOps | tests/, infra/, .github/ |

## 5. Mốc & cổng
| Mốc | Tuần | Tiêu chí |
|---|---|---|
| Gate 1 – Design freeze | 2 | SRS v1, openapi v0.2, ERD, mock chạy |
| Gate 2 – End-to-end | 5 | Đơn → hóa đơn sandbox → sổ cái |
| Gate 3 – Tax đúng | 8 | Khớp bảng giảng viên |
| Gate 4 – Feature freeze | 10 | Dừng thêm tính năng |
| Test/báo cáo/bảo vệ | 11–12 | UAT-01..15, báo cáo |

## 6. Quy tắc làm việc
Contract-first (openapi là hợp đồng), PR + cross-review, main được bảo vệ, mỗi thư mục một chủ, họp ngắn 2 lần/tuần, cập nhật backlog hằng tuần.

## 7. Rủi ro
| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Quy định thuế đổi/không chắc | Cao | Tham số hóa, chốt GV, ghi legal_basis |
| Không khảo sát được hộ thật | Trung bình | Persona giả định gắn nhãn rõ + hỏi GV |
| Lệch API giữa mobile/backend | Cao | Mock Prism + lint CI |
| Sync lỗi trùng đơn | Cao | client_op_id idempotent + test |
| Một người quá tải | Trung bình | Review chéo, theo dõi backlog |
| Docker không chạy trên máy | Thấp | Hướng dẫn chạy không Docker |

## 8. Phê duyệt
Giảng viên: ____  Nhóm trưởng: ____  Ngày: ____
