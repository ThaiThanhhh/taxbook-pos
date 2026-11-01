# Snapshot nháp lưu bền — Ledger & Tax

Nhánh từ HEAD PR #8 `cd69727`. Các PR #5–#8 và nhánh Dũng chưa có commit mới khi
fetch. Config thuế vẫn DRAFT_UNVERIFIED; không có BR mới cho tính/chốt thuế chính thức.

## Cách dùng nội bộ

`TaxPeriodService.prepareSnapshot(household, periodId)` nay lưu snapshot xuống
`tax_draft_snapshot`, trả thêm `id`, `source_revision`, param fingerprint và timestamp DB.
Giữ totals/range/status/digest hiện có. `readSnapshot(household,id)` đọc từ DB,
thêm `stale` và `current_source_revision`. Không có API công khai mới.
Service mới sau restart có thể đọc lại cùng ID; không dùng cache/memory để giữ snapshot.

Đọc Ledger, lấy revision và INSERT snapshot cùng transaction, lấy khóa theo thứ tự
household → period. Chỉ cho kỳ DRAFT; không cập nhật số thuế hoặc trạng thái kỳ.
Hai yêu cầu cùng revision/nội dung dùng UNIQUE + ON CONFLICT để trả cùng snapshot ID;
khác revision/nội dung tạo bản nháp mới. Không xóa các snapshot cũ.

Mọi snapshot giữ status=DRAFT, official=false, tax_result=NULL bằng constraint kể cả
khi có param_set_id APPROVED. Đây không phải luồng chốt pháp lý. Param ID/version/status
và hash payload DB được giữ tại lúc chụp, không biến cấu hình nháp thành dữ liệu chính thức.

## Nhận biết dữ liệu thay đổi

Trigger PostgreSQL BEFORE INSERT/UPDATE/DELETE của ledger_entry tăng revision theo
household trong chính transaction ghi sổ, gồm cả chỉnh sửa không làm đổi tổng tiền.
Rollback cũng rollback revision. Không dựa digest tổng hợp để khẳng định Ledger chưa đổi.
Snapshot ghi revision dạng bigint; API nội bộ trả revision dạng chuỗi để không mất độ chính xác.

readSnapshot kiểm tra revision hiện tại, ngày/trạng thái kỳ và metadata/payload tham số
trong một SELECT nhất quán (khóa writer vẫn giữ khi tạo snapshot). Nếu khác, stale=true. Thay Ledger ngoài khoảng kỳ
vẫn có thể đánh dấu stale: đây là kiểm tra bảo thủ theo household. OCR chưa xác nhận
không thay Ledger nên không làm stale totals đã ghi sổ; xác nhận OCR thì có.
Sau khi đọc xong transaction, writer có thể tiếp tục: trạng thái freshness chỉ đúng tại
thời điểm kiểm tra. Snapshot nháp không phải bản đóng băng/bằng chứng bất biến Ledger.

Không hỗ trợ sửa revision thủ công, tắt trigger hay TRUNCATE Ledger trong vận hành
runtime. Đây là thao tác DBA ngoài service; nếu bảo trì kiểu đó phải đánh dấu/rebuild
nháp có liên quan. Với batch nhiều household phải khóa theo thứ tự nhất quán và retry
deadlock/serialization khi có lỗi. Luồng xác nhận kỳ tương lai phải dùng cùng thứ tự khóa.

## SQL và áp dụng

SQL nền persistence: `migrations/proposals/tax-draft-snapshot.sql`, **chưa cấp số**;
index danh sách bổ sung ở `snapshot-list-index.sql`, áp dụng sau file nền.
Bootstrap DB mới: baseline schema Ledger/Tax rồi hai SQL proposal trong transaction.
Nâng cấp DB cũ từ PR #8: chỉ chạy proposal một lần trong transaction, không bootstrap.
File không DROP/TRUNCATE/xóa financial rows; thêm revision, trigger, bảng snapshot,
composite FK household/period, FK param/household revision, CHECK money/official/draft,
unique dedup và index đọc snapshot theo kỳ/thời gian. Trigger cũng bảo vệ kỳ DRAFT
khi ghi SQL trực tiếp; ownership/period của snapshot không được đổi.

Sau review và được cấp migration theo quy ước nhóm, ví dụ DBA áp dụng trên DB đã
backup bằng psql với `--single-transaction --set ON_ERROR_STOP=1 --file` trỏ tới file.
Không tự chạy vào DB nhóm. Proposal không idempotent: chạy lại sẽ báo lỗi và phải
rollback toàn bộ; runner tương lai phải ghi lịch sử đã áp dụng. ALTER TABLE/CREATE
INDEX cần khóa, nên DBA xem kích thước bảng và chọn cửa sổ triển khai. Không đổi lịch
sử migration đã merge. Thư mục migrations hiện chỉ có README, chưa có runner nhóm.

## Kiểm thử và giới hạn

Giữ 34 bài cũ, thêm 4 bài tích hợp về persistence/restart/cùng request, equal-total
edit và rollback revision, failed INSERT/constraints/confirmed, migration schema cũ.
Test cũ tiếp tục kiểm tra ranh giới ngày, OCR, hủy, overflow và snapshot vs concurrent writer.
Migration được test trên baseline trống và schema cũ có dữ liệu; schema nâng cấp test
riêng được rollback toàn bộ. CI dùng PostgreSQL 16 disposable và PGlite.

Chưa có tính/chốt thuế chính thức vì config/tax/tax-params.v0.json là DRAFT_UNVERIFIED,
SRS/tax-rules vẫn placeholder. Chưa có Sales thật ở nhánh Dũng, vẫn dùng SalesLedgerPort
và fake caller. Hai API Reports vẫn thiếu quy tắc lợi nhuận/payment mapping như PR #8.
Các phần này không chặn snapshot nháp. Không thay OpenAPI hoặc dependency.

## Danh sách và freshness hàng loạt (bổ sung trên PR #9)

`TaxPeriodService.listSnapshots(household,{period_id?,limit?,cursor?})` trả metadata,
totals, stale/stale_reasons và next_cursor. Mặc định 50, tối đa 200; SQL chỉ lấy limit+1.
Keyset tăng dần (created_at,id), cursor gắn hộ/kỳ và giữ 6 chữ số microsecond của DB
(không lấy thời gian đã bị JS Date làm tròn xuống millisecond). Không mở API mới.

`snapshotFreshness(household,ids)` tối đa 200 UUID, bỏ ID trùng, bỏ cả ID không tồn tại
và thuộc hộ khác. Không tiết lộ hộ sở hữu. Một SELECT JOIN lấy snapshot/revision/kỳ/
tham số, không N+1. readSnapshot dùng cùng cơ chế, giữ 404 khi không tìm thấy.
Lý do: LEDGER_REVISION_CHANGED, PERIOD_NOT_DRAFT, PERIOD_RANGE_CHANGED,
PARAM_CONTEXT_CHANGED. Không suy ra kỳ cụ thể nào thay đổi chỉ từ household revision.

Đọc freshness dùng MVCC của một statement để lấy toàn bộ context nhất quán, không cần
khóa writer cho từng bản ghi; chỉ đúng tại thời điểm SELECT. Khóa khi tạo snapshot giữ
nguyên. Index bổ sung trong proposals/snapshot-list-index.sql cho trường hợp không lọc
kỳ; period-filtered vẫn dùng index cũ. SQL mới được test cùng bootstrap và upgrade.

Test thêm 1.001 snapshot với timestamp trùng/khác microsecond, paging không mất/trùng,
batch 200 chỉ một query và test PostgreSQL dùng hai Pool/backend PID khác nhau để chạy
12 request/3 kỳ/2 hộ cùng hai writer. Chế độ PGlite skip test multi-connection vì chỉ
có engine đơn; CI PostgreSQL 16 phải chạy bài đó. Không gọi Promise.all PGlite là bằng
chứng nhiều connection. Không benchmark/khẳng định SLA từ dataset test.

Migration index là đề xuất chưa cấp số, không sửa proposal trước. CREATE INDEX thông
thường có thể chặn ghi bảng snapshot trong lúc dựng index; thời gian production chưa
đo vì không dùng DB nhóm. DBA xem kích thước, EXPLAIN và chọn cửa sổ/CONCURRENTLY theo
runner trước triển khai. Không tự thay bằng migration online mà runner chưa hỗ trợ.

## Checklist bàn giao chuỗi PR #5–#9

Khi kiểm tra: tất cả còn Draft, reviews=[], MERGEABLE; #6–#9 có CI xanh ở HEAD cũ,
#5 chưa có checks. Merge-base mỗi cặp đúng HEAD parent: d49bf4c → a895274 → 973b49c
→ cd69727 → 5d551a6. Không có code Dũng mới ngoài skeleton. Không tự merge.

1. Review diff theo thứ tự #5 (nền) → #6 (integration) → #7 (fix) → #8 (summary)
   → #9 (persistence + query). Dũng review backend/schema; Tấn Tài review test/CI.
2. Chạy CI trên HEAD cuối, xác nhận migration chỉ test DB độc lập, không có secrets;
   BA xác nhận phạm vi chưa có thuế chính thức. #5 cũng cần build/test review.
3. Sau đủ approval, đề xuất gom bằng merge commit từ nhánh con lên parent: #9 vào
   #8, #8 vào #7, #7 vào #6; giữ lịch sử, không force-push/rebase/squash tự động.
   Sau mỗi bước kiểm tra diff/base và chạy lại CI/review nếu approval bị vô hiệu.
4. Cuối cùng merge #5 vào main rồi retarget nhánh tích hợp #6 về main, review diff
   tổng và CI trước merge. Cách này tránh đưa integration thiếu bản sửa #7 lên main.
   Chủ repo quyết định cách merge; checklist không phải ủy quyền merge.
5. Sau merge code, Dũng/DBA cấp số và chuẩn hóa migration runner; chỉ triển khai SQL
   sau review/backup. Cấu hình thuế và luồng chốt vẫn chờ BR, không tự bật production.
