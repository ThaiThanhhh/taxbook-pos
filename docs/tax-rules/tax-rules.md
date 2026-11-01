# Quy tắc thuế hộ kinh doanh – v1.1 (DRAFT_UNVERIFIED)
Chủ: Ngọc Thái. Dữ liệu máy đọc: `config/tax/tax-params.v1-draft.json`. Bản đọc kèm (có ví dụ): tài liệu  "Bảng tham số thuế & bộ câu hỏi khảo sát".

## 1. Nguồn đã đọc (chưa có toàn văn)
| Nguồn | Dùng cho | Hạn chế |
|---|---|---|
| Công văn Thuế tỉnh Đồng Nai triển khai NĐ 68/2026 và TT 18/2026 | Tỷ lệ ngành, phương pháp TNCN, kỳ khai, sổ, hóa đơn | Viết theo ngưỡng cũ 500 triệu; bảng lệch định dạng |
| Tóm tắt NĐ 141/2026/NĐ-CP (xaydungchinhsach.chinhphu.vn) | Đổi 500 triệu → 1 tỷ; hóa đơn điện tử; hiệu lực 01/01/2026 | Chỉ là bản tóm tắt |
Việc cần làm: tải toàn văn NĐ 68/2026, NĐ 141/2026, TT 18/2026, TT 152/2025 từ Công báo/CSDL văn bản, đối chiếu từng Điều.

## 2. Ngưỡng và phương pháp
| Doanh thu năm | GTGT | TNCN | Kỳ khai | Quyết toán | HĐĐT | Sổ |
|---|---|---|---|---|---|---|
| ≤ 1 tỷ | Không nộp | Không nộp | 1 lần/năm, trước 31/01 | Không | Không bắt buộc | S1a-HKD |
| > 1–3 tỷ | DT × tỷ lệ | Cách 1: (DT − 1 tỷ) × tỷ lệ; Cách 2: (DT − chi phí) × 15% | Quý | Chỉ cách 2 | Bắt buộc | S2a (cách 1); S2b–S2e (cách 2) |
| > 3–50 tỷ | DT × tỷ lệ | (DT − chi phí) × 17% | Quý | Có | Bắt buộc | S2b–S2e |
| > 50 tỷ | DT × tỷ lệ | (DT − chi phí) × 20% | Tháng, trước ngày 20 | Có | Bắt buộc | S2b–S2e |

## 3. Tỷ lệ theo nhóm ngành
| Mã cấu hình | Nhóm | GTGT | TNCN cách 1 |
|---|---|---|---|
| GOODS_DISTRIBUTION | Phân phối, cung cấp hàng hóa | 1% | 0,5% |
| SERVICE | Dịch vụ, xây dựng không bao thầu NVL | 5% | 2% |
| PRODUCTION_TRANSPORT | Sản xuất, vận tải, dịch vụ gắn hàng hóa, xây dựng có bao thầu NVL | 3% | 1,5% |
| OTHER | Hoạt động khác | 2% | 1% |
| RENTAL_AGENT | Cho thuê tài sản, đại lý bảo hiểm/xổ số/đa cấp | – | 5% |
| DIGITAL_CONTENT | Nội dung số | – | 5% |

Ánh xạ tạm cho 3 hộ khảo sát (phỏng đoán, cần xác nhận): tạp hóa → GOODS_DISTRIBUTION; quán cơm → PRODUCTION_TRANSPORT; sửa xe → SERVICE (nếu bán phụ tùng kèm: tách doanh thu sang GOODS_DISTRIBUTION).

## 4. Quy tắc phụ
- Doanh thu gồm cả tiền chưa thu; trừ chiết khấu thương mại, giảm giá, hàng trả lại.
- Chi phí được trừ: thực tế, liên quan, có chứng từ; từ 5 triệu đồng trở lên phải thanh toán không dùng tiền mặt.
- Đã chọn cách 2 thì giữ 2 năm; doanh thu cả năm vượt 3 tỷ thì năm sau chuyển cách 2.
- Hộ mới nửa đầu 2026: khai 31/07/2026 và 31/01/2027; nửa cuối: 31/01/2027.
- Đăng ký HĐĐT trong 30 ngày kể từ ngày cuối kỳ tính thuế có doanh thu vượt 1 tỷ.

## 5. Điểm chưa chốt
Xem `docs/charter/lecturer-questions.md` (Q1–Q10) và `open_questions` trong JSON. Thêm: mốc biên 1 tỷ; kỳ khai/quyết toán khi vượt ngưỡng giữa năm; Luật TNCN 109/2025/QH15.

## 6. Lịch sử thay đổi
| Ngày | Phiên bản | Thay đổi |
|---|---|---|
| 2026-11-01 | v1.1-draft | Ngưỡng 1 tỷ (NĐ 141), thêm khung theo doanh thu, kỳ khai, sổ, HĐĐT |
