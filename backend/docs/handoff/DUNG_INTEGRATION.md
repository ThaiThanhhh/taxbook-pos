# Đầu vào cần Quang Dũng cung cấp để tích hợp thật

Source đã kiểm tra sau fetch ngày 06/11/2026: PR #5, nhánh
feature/QDung-backend-sales-invoice tại f09690dc4f749d7b3e0486f159cfae20b2a95c48.
Dũng đã merge main và thêm pg/@types/pg cùng mẫu DB_*. PR #6 đồng bộ bằng merge
commit, giữ range @types/pg ^8.23.1 và cả hai bộ biến môi trường; Ledger/Tax vẫn dùng
DATABASE_URL, chưa đọc DB_*. Hiện có NestJS skeleton/test controller; các thư mục
Sales/Auth/Catalog/Invoice/Sync chỉ có README, chưa có implementation giao dịch hoặc
DB wiring chung mới. Các contract cần cung cấp dưới đây vẫn chưa được giải quyết.

Merge đồng bộ vào #6: `4499d5418a0037ab3869448f8b35557a7be9a779`, CI
[PR](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215866913)/
[push](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215862263) SUCCESS.
Kiểm tra feedback ngày 06/11/2026: chưa có review/approval hoặc xác nhận các contract
bên dưới từ Dũng/Tấn Tài. Driver và env examples đã có, các mục integration thật
vẫn là việc mở, không được đánh dấu đã xong chỉ vì merge nền thành công.

Đây là danh sách quyết định/contract cần cung cấp, không phải đề xuất tự tạo schema
hoặc giao thức thay Dũng. Ledger đã có seam; kết nối thật cần đầu vào sau:

| Nhóm | Dũng cần cung cấp/xác nhận | Ledger hiện dùng | Điều kiện nghiệm thu tích hợp thật |
| --- | --- | --- | --- |
| Sale lifecycle | Trạng thái nào là accepted/persisted; ID ổn định, ownership và mapping field; thời điểm gọi Ledger | [SalesLedgerPort](../../src/modules/ledger/sales-ledger.contract.ts), không có Sales HTTP API riêng | Chỉ sale accepted được post; draft/rejected không post; retry dùng cùng ID |
| Date/money/sector | Nguồn ngày bán gốc, timezone nghiệp vụ, tiền VND integer, sector và payment mapping | entry_date YYYY-MM-DD; sector GOODS_DISTRIBUTION/SERVICE/PRODUCTION_TRANSPORT/OTHER; CASH/QR_TRANSFER/CARD; tổng payments phải bằng amount | Fixture thật cho từng mapping; không tự đổi ngày bán sang ngày retry hoặc tự quyết định ngành tính thuế |
| Transaction | Chọn pg SqlClient cùng transaction/DB, hoặc durable outbox do Sales sở hữu; retry/dead-letter/observability nếu chọn outbox | recordSale/reverseSale nhận optional client; không truyền client thì Ledger có transaction riêng, không atomic dual-write | Lỗi caller rollback cả Sales/Ledger khi shared client; outbox thì chứng minh retry an toàn/eventual delivery và xử lý lỗi |
| Cancellation | Khi nào hủy hợp lệ; full/partial refund, ngày điều chỉnh và retry contract | reverseSale đảo toàn bộ entries gốc theo ngày gốc, từ chối kỳ khóa; chưa có partial refund API | Sale cancel + reversals atomic hoặc qua outbox; thử duplicate cancel, kỳ khóa; phần refund khác chờ contract/BA |
| Household schema | Bảng/PK/type/lifecycle của household và sale; quan hệ membership/ownership; migrations để ánh xạ ID | household_id text và sale ref_id text; chưa có FK tới bảng Household/Sales thật | ID mapping được review trước FK/migration; không orphan hoặc chuyển ownership ngoài quy trình |
| Auth | Issuer/audience/signing approach, trusted household claim, role matrix, token/membership lifecycle và cách nối guard chung | [LedgerAuthGuard](../../src/common/http.ts): HS256, JWT_SECRET >=32, iss taxbook-pos, aud taxbook-pos-api, exp bắt buộc; OWNER/ACCOUNTANT/ADMIN; STAFF bị từ chối | Token thật qua guard, sai/expired/khác hộ bị chặn; nếu dùng JWKS/thuật toán/claims khác phải thống nhất adapter, không tự chấp nhận |
| DB/module wiring | Pool/ORM/client chung, cách inject provider và lifecycle đóng connection; chuẩn transaction isolation | [Database](../../src/common/database.ts), module register, household lock trước period lock | Một bootstrap Nest, không hai pool/transaction giả atomic; caller propagate lỗi; không chờ mạng trong transaction; batch khóa hộ theo thứ tự nhất quán |
| Production migration | Runner và số thứ tự chung, mapping baseline mới/DB cũ, SQL review, quyền trigger/function/index và lịch triển khai | SQL baseline/proposals chưa cấp số; runner chỉ nhận test DB/schema riêng | Migration production được review/cấp số; fresh/upgrade có rehearsal, backup/restore/rollback plan, không bootstrap DB có dữ liệu |
| Revision/DB writes | Writer nào được phép sửa Ledger; bulk import, maintenance, trigger và revision contract | Trigger cùng transaction cho INSERT/UPDATE/DELETE; household revision bigint dạng chuỗi; TRUNCATE/tắt trigger/reset tay không được freshness hỗ trợ | Writer thật dùng cùng lock/transaction; quy trình bảo trì có đánh dấu/rebuild snapshot, không quảng bá TRUNCATE là thao tác đã test |

Không yêu cầu Dũng phê duyệt luật thuế thay BA. Ngọc Thái/BA phải cung cấp BR đã duyệt
cho bases/ngưỡng/làm tròn/phân bổ/chốt kỳ/điều chỉnh/tờ khai và semantics tham số bất biến.
Tấn Tài review tests/CI và môi trường demo; Dũng review backend/contract/SQL.

Đã đối chiếu nhánh BA 0119d73: SRS v1/backlog/UAT và config v1 có ở nhánh riêng nhưng
vẫn là draft, chưa tích hợp/phê duyệt. Loader hiện tại chưa nhận schema v1 (thiếu
effective_from, pit_methods object thay array, pit_ratio thay pit_revenue). BA/Hoài Bảo
cần chốt schema trước khi nối vào runtime; Dũng không phải người tự phê duyệt luật.
Tiêu chí auto-match ≥80%, cảnh báo ngưỡng và các API chưa có được ghi đầy đủ trong
[ma trận yêu cầu](REQUIREMENTS_STATUS.md), không phải các contract đã hoàn tất.

## Việc cần Dũng xử lý ở PR #5

- [ ] Chuẩn bị workflow/CI phù hợp skeleton #5, xử lý lỗi validation thực tế nếu có.
- [ ] Chuyển Ready khi phù hợp và xin review chéo; author không tự approve.
- [ ] Merge #5 theo quy trình nhóm sau CI/review hợp lệ; báo merge SHA và main SHA mới.
- [ ] Chốt các contract trên và reviewer cho PR #6 tổng hợp.

Nguyên nhân #5 chưa có CI đã xác minh: .github/workflows rỗng ở cả HEAD #5 và main;
workflow backend thêm ở #6, không có trong lịch sử #5. GitHub trả 0 runs/checks cho
f09690d; không phải job đang chạy hay bị chặn chỉ vì Draft. Không copy nguyên workflow
Ledger sang skeleton nếu scripts/tests chưa tồn tại. Lượt bàn giao không sửa hoặc merge #5.

## Gate để retarget/merge #6

Chừng nào #5 còn OPEN thì giữ base #6 ở nhánh Dũng. Sau #5 merge hợp lệ: fetch main,
xác minh ancestry/merge SHA và các thay đổi mới, retarget #6 về main; kiểm tra diff/
conflicts, CI đúng HEAD/base mới, review Dũng/Tấn Tài và protection/rules hiệu lực.
Không dùng reviews/checks từ SHA cũ thay approval mới, không tự bypass main hoặc bật
auto-merge. Các điều kiện triển khai production vẫn cần hoàn tất riêng trước deploy.
