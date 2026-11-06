# Đối chiếu yêu cầu và phân loại phần việc Ledger & Tax

Ngày 06/11/2026; implementation 4499d5418a0037ab3869448f8b35557a7be9a779,
PR #6, base Dũng f09690d. Nguồn phân công:
[README](../../../README.md), [Ledger README](../../src/modules/ledger/README.md),
[Tax README](../../src/modules/tax/README.md), [OpenAPI](../../../api/openapi.yaml),
[SRS](../../../docs/srs/README.md), [tax rules](../../../docs/tax-rules/README.md),
[config tax](../../../config/tax/README.md).

SRS/tax-rules trên nhánh tích hợp còn là README placeholder. Đã kiểm tra thêm nhánh BA
`ngoc-thai/BA-lead` tại `0119d73`: có [SRS v1](https://github.com/ThaiThanhhh/taxbook-pos/blob/0119d73/docs/srs/srs-v1.md),
[backlog](https://github.com/ThaiThanhhh/taxbook-pos/blob/0119d73/docs/srs/backlog.csv),
[UAT](https://github.com/ThaiThanhhh/taxbook-pos/blob/0119d73/docs/test-plan/uat.md) và
[tax rules](https://github.com/ThaiThanhhh/taxbook-pos/blob/0119d73/docs/tax-rules/tax-rules.md).
SRS ghi Dự thảo/mục CHỐT chờ giảng viên; tax rules/config v1 vẫn DRAFT_UNVERIFIED,
chưa có PR của nhánh BA khi kiểm tra. Dùng để truy vết khoảng trống, không coi là luật
đã duyệt hoặc tự merge vào runtime. Mã FR/US dưới đây lấy nguyên tài liệu BA, không tự đặt.

## A — Đã hoàn thành và có test chứng minh trong phạm vi kỹ thuật

| Nguồn/yêu cầu | Phần đã có | Bằng chứng và giới hạn |
| --- | --- | --- |
| README, Ledger README: sổ tự động theo ngày bán | SalesLedgerPort/shared transaction, ngày bán gốc, chống trùng và reversal | Tests accepted-sale/caller rollback/cancellation/concurrent retry; Fake Sales đã PASS. Caller Sales thật còn C |
| GET /ledger | Household scope, book/range/cursor/limit và tiền integer VND | Tests API, pagination, invalid input, isolation. Mapping book chuẩn S1A/S2A còn C |
| POST /expenses; POST /expenses/{id}/confirm | Manual ghi ngay; OCR chờ confirm; idempotency và kỳ khóa | Manual/OCR/concurrent-confirm/rollback tests; OCR extraction của AI không nằm trong implementation này |
| POST /bank-statements/import; GET /bank-statements/matches; POST /bank-statements/{id}/match | CSV fixture/validation/retry, suggestion, CONFIRM/UNMATCH, bảo vệ old-match kỳ khóa | CSV/HTTP limit/match race/locked replacement tests; không phải bank feed production |
| Ledger README: ledger_entry/expense/bank_statement_line schema | SQL baseline/constraints/index và rehearsal | Fresh/legacy upgrade/rollback tests; số migration và triển khai DB thật còn C |
| Tax README: tax_param_set/tax_period schema | Metadata version/DRAFT/CONFIRMED, param FK và period scope | Schema/service tests. CONFIRMED là fixture để thử khóa, chưa có API chốt thật |
| Tax README: nạp tham số có version/ngày; GET /tax/params | Validate/load/select effective approved params; không public draft | Tax loader/date/duplicate/overlap tests; HTTP draft hiện trả 404 đúng gate. Chưa có bộ APPROVED thật |
| Tax README tuần 1: engine thuần + hai ví dụ | Số học BigInt trên bases và rounding caller chỉ định, RATIO_REVENUE | Hai phép tính hàng hóa/dịch vụ, rounding/negative/duplicate-sector tests; DEMO không tự suy ra taxable bases hoặc PROFIT_15 |
| GET /tax/periods | Liệt kê kỳ theo household, giữ DRAFT/CONFIRMED của hợp đồng | API state/isolation tests. Không bao hàm calculate/confirm endpoints |
| Phạm vi PR #8: aggregation | Tổng POSTED REVENUE/EXPENSE/reversals, DAY/MONTH/range, overflow/cursor | Summary/date/overflow tests; không tự diễn giải thành profit/cashflow |
| Phạm vi PR #9: snapshot | Persist/dedup/read từ pool mới, revision/freshness/context, listing/batch | Persistence/revision/rollback/1.001-row/microsecond/one-query/multi-connection tests; service nội bộ |
| Phạm vi rehearsal/demo | Tracking/checksum/plan-prefix, atomic rollback, legacy upgrade, 12 migration và DB test isolation | 3 rehearsal tests + terminal demo PASS; không phải production runner |
| NFR hỗ trợ | JWT guard riêng, household isolation, validation/error envelope, safe integer tiền và transaction rollback | Tests auth/issuer/audience/expiry/role/overflow/error/concurrency. Không phải chứng nhận toàn bộ security/performance NFR |

Tên test và tiêu chí quan sát chi tiết: [ACCEPTANCE.md](ACCEPTANCE.md).
Các response/path được đối chiếu với controller và các test hiện có; chưa có báo cáo
OpenAPI conformance tự động bao phủ mọi schema/response. Không gọi đây là chứng nhận
toàn bộ OpenAPI đã được triển khai.

## B — Có implementation/bằng chứng tự động, chờ nghiệm thu thủ công

- Dũng xác nhận shared transaction/client, base NestJS, hợp đồng SalesLedgerPort và
  SQL/locks phù hợp kiến trúc chung; ký tại SHA đã xem hoặc Approve bằng tài khoản thật.
- Tấn Tài quan sát demo lặp sạch, 41 PostgreSQL tests/3 rehearsal tests, đọc CI và
  kiểm tra các failure/isolation cases; ghi run/SHA, feedback và kết quả.
- Mentor quan sát bài demo/phần việc cá nhân nếu buổi nghiệm thu yêu cầu. Test PASS
  chưa phải đã trình bày hoặc có chữ ký nghiệm thu.

Không có chức năng nào được tuyên bố nghiệm thu nghiệp vụ chỉ dựa vào agent review.
Các mục A vẫn có thể cần xác nhận B; hai nhãn này không thay thế nhau.

## Đối chiếu SRS/backlog dự thảo của BA

| FR/US/UAT gốc | Phân loại hiện tại | Đối chiếu bằng chứng / phần chưa có |
| --- | --- | --- |
| FR-08 / US-09 / UAT-05 hủy bằng reversal | A cho Ledger; B/C cho end-to-end Sales | Reversal/retry/rollback đã test; Sales cancel thật chờ Dũng |
| FR-09 / US-10 / UAT-06 ngày từ client_created_at | A một phần, B/C | Port giữ entry_date gốc; chưa có mapping client_created_at/timezone từ Sales thật hoặc UI mobile |
| FR-10 / US-11,12 / UAT-07,08 chi phí/OCR | A backend; B/C end-to-end | Manual/confirm đã test; AI OCR/UI và phần lợi nhuận trong UAT-07 chưa nghiệm thu |
| FR-11 / US-13 / UAT-09 tự khớp ≥80% | A import/suggestion/manual-confirm; C tiêu chí auto-match | Code trả auto_matched=0 và cần CONFIRM; chưa có đo tỷ lệ/tự khớp ≥80%, không đánh dấu UAT-09 PASS |
| FR-12 / US-14 / UAT-10 tính thuế khớp bảng giảng viên | A arithmetic DEMO; C nghiệp vụ | Chưa có policy bases/brackets/PROFIT_15,17,20 hoặc kiểm chứng TV-01–TV-06 của BA; hai ví dụ core không thay UAT-10 |
| FR-13 / US-14,17 / UAT-10,12 tờ khai/chốt kỳ | A snapshot và guard khóa; C workflow | Snapshot nội bộ không phải file tờ khai; CONFIRMED fixture không phải đã triển khai API chốt |
| FR-14 / US-15 / UAT-13 cảnh báo 80%/100%, nhắc hạn | C | Chưa có threshold-warning/reminders service/API; chờ ngưỡng/kỳ hạn được duyệt và UI/channel contract |
| FR-15 / US-18 báo cáo lãi/top hàng/cashflow | A summary; C report endpoints | Chưa có ba route báo cáo, mapping Sales/cost/returns hoặc quy tắc lợi nhuận/dòng tiền |
| FR-17 / US-16 / BR-04 / UAT-11 version tham số | A loader/metadata/fingerprint; C admin lifecycle | Chưa có PUT admin, enforcement immutable approved versions hoặc workflow đổi version giữ kỳ cũ; stale detection không thay BR-04 |
| FR-18 nhật ký thao tác nhạy cảm | A reversal/history; C audit log tổng quát | Chưa có audit log chung cho Auth/Admin/chốt kỳ; BA/nhóm cần chốt owner/events/retention |
| NFR-03 idempotency | A Ledger; C toàn bộ sync | Retry Ledger/expense/import/reversal đã test; không phải test client_op_id/device/local_seq của sync thật |
| NFR-04 / UAT-15 phân hộ và bảo mật | A guard/isolation; B/C Auth thật | Chưa chứng minh password hashing/HTTPS/membership production bằng JWT test |
| NFR-05 error envelope; NFR-07 CI | A trong module hiện có, B QA review | Error-envelope/validation tests và CI có; chưa phải full-system OpenAPI conformance |

FR-01–FR-07 (Auth/Sales/Sync/Invoice), FR-16 (AI), NFR-01/02/06 (offline/tải/UI) thuộc
đầu ra thành viên khác; không nghiệm thu thay các phần đó. US-19 giao phần nhắc UI
cho Mai Trinh, còn contract backend/reminders và luật hạn vẫn là dependency nhóm.

## C — Chưa hoàn thành / phụ thuộc nhóm hoặc quyết định nghiệp vụ

| Yêu cầu còn thiếu | Trạng thái thật | Đầu vào/owner cần có |
| --- | --- | --- |
| Sales thực, Auth/Household chung | Chỉ port + Fake Sales + JWT test; base Dũng chưa có nghiệp vụ tương ứng | Dũng: lifecycle/ID/date/sector/payment/cancel mapping, shared transaction hoặc outbox, trusted claims/membership/role contract |
| Mẫu sổ chuẩn S1A/S2A và mapping ngành | Ledger book/filter tổng quát; không có mapping mẫu pháp lý đã duyệt | BA/Ngọc Thái: mẫu, cột, ngành và BR; Dũng/Hoài Bảo thống nhất data mapping |
| POST /tax/periods/{id}/calculate | Chưa đăng ký route; engine chỉ là arithmetic core | BA: bases/ngưỡng/phân bổ/rounding/phương pháp thuế; dữ liệu Sales/expense và API policy |
| POST /tax/periods/{id}/confirm | Chưa đăng ký route, chưa có workflow chốt/điều chỉnh kỳ thật | BA: trạng thái, immutable params/ledger và điều chỉnh kỳ; Dũng: auth/transaction chung |
| GET /tax/periods/{id}/return-draft | Chưa có xuất tờ khai PDF/XLSX | BA: mẫu, field, legal references và approval. Tax Draft Snapshot nội bộ không phải tờ khai này |
| GET /reports/daily-profit | Chưa có route/backend report | BA: định nghĩa profit/cost; Dũng: Sales/returns mapping. Không tự coi revenue-expense là accounting profit |
| GET /reports/top-products | Chưa có backend route/query | Dũng: sale line/product/return schema và contract; BA chốt cách xếp hạng, QA test. Không tự viết Sales hoặc phần mobile của Mai Trinh |
| GET /reports/cashflow | Chưa có route/backend report | BA: semantics dòng tiền; Dũng: receipts/refunds và payment mapping chi phí |
| GET /reminders | Chưa có route, lịch tính nhắc hạn | BA: filing_period/deadlines/timezone; Dũng: auth/channel contract khi cần |
| Cảnh báo ngưỡng FR-14 / US-15 | Chưa có service/API hoặc kiểm thử cảnh báo 80%/100% | BA chốt threshold/biên/năm và UX contract với Mai Trinh; không suy ra từ totals |
| PUT /admin/tax-param-sets | Chưa có route/lifecycle phê duyệt/lưu bộ tham số qua API | BA: version/approval/immutability; Dũng: quyền Admin/Auth và migration chung |
| Thuế chính thức/PROFIT_15 | Không được cung cấp như nghiệp vụ hoàn tất; config vẫn DRAFT_UNVERIFIED/TO_BE_CONFIRMED | BA/Ngọc Thái duyệt BR và param set; không biến ví dụ DEMO thành nghĩa vụ pháp lý |
| Schema tham số v1 trên nhánh BA | Chưa tương thích loader v0, chưa tích hợp vào #6 | BA/Hoài Bảo thống nhất effective_from, pit_methods array/object, pit_ratio/pit_revenue, brackets và ngành; không đổi loader trong lượt đóng gói |
| Migration production | SQL đề xuất/rehearsal đã có; chưa có numbering/runner/deployment đã duyệt | Dũng/DBA: số migration, baseline mapping, backup/restore, locks/index/permissions và rollout plan |
| Main integration | #6 Ready nhưng chưa approved; #5 Draft/chưa CI/chưa merge | Dũng/Tấn Tài review; #5 merge hợp lệ rồi retarget #6, kiểm tra diff/CI/approval/protection lại |

Các route C được ghi trong OpenAPI nhưng chưa triển khai; đây là khoảng trống có chủ
đích cần thống nhất phạm vi nghiệm thu với nhóm, không được đánh dấu A. Đặc biệt,
README giao cả module tính/chốt thuế/báo cáo; vì vậy không thể kết luận toàn bộ phạm vi
Tax ban đầu của cá nhân đã hoàn tất chỉ vì demo snapshot chạy tốt.

## D — Lỗi thực tế được ghi nhận

Tại thời điểm kiểm tra, PR #6 không có review, requested changes, review thread hoặc
comment; CI 4499d54 đạt, chưa có lỗi runtime tái hiện được hoặc lỗi reviewer có căn
cứ cần sửa ở lượt đóng gói. Điều này không chứng minh không còn lỗi tiềm ẩn, không
chuyển các mục C thành đã hoàn thành và không thay human approval.

Khoảng trống tương thích v1 đã tái hiện read-only: đưa JSON v1 từ nhánh BA vào
validateParams hiện tại trả Invalid input. JSON không có effective_from, pit_methods
là object và rate dùng pit_ratio thay pit_revenue; loader v0 yêu cầu dạng khác. Đây
là integration gap có bằng chứng với draft ngoài nhánh, không phải lỗi phát sinh
trong cấu hình v0 đang chạy. Không nạp v1 hoặc tuyên bố hỗ trợ v1 trước khi chốt schema.

Không sửa source trong lượt này. Các lỗi từng gặp và đã sửa (old-match lock, rollback
connection, history ORDER BY id với migration 10/2) có regression đã nằm trong #6.
