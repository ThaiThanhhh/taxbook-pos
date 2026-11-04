# config/tax/ – chủ: Ngọc Thái (viết), Hoài Bảo (đọc)

Bảng tham số thuế dạng JSON có phiên bản. Mã backend đọc file này, không viết cứng ngưỡng hay tỷ lệ.

| File | Trạng thái |
|---|---|
| tax-params.v0.json | Cũ (ngưỡng 1 tỷ chưa có khung theo doanh thu) – chỉ để tham khảo |
| tax-params.v1-draft.json | **Dùng để dev**; `DRAFT_UNVERIFIED` – ngưỡng 1 tỷ (NĐ 141/2026), khung theo doanh thu, kỳ khai, sổ, HĐĐT |

Mọi giá trị chưa xác minh phải mang `DRAFT_UNVERIFIED` và không dùng để khẳng định nghĩa vụ thuế thực tế. Nguồn, điểm chưa chốt, lịch sử: `docs/tax-rules/tax-rules.md`. Test vector: `docs/test-plan/tax-test-vectors.csv`.

Hoài Bảo: đọc `brackets[]`, `rates{}`, `pit_methods{}`; kỳ đã tạo giữ nguyên version tham số tại thời điểm tạo (BR-04).
