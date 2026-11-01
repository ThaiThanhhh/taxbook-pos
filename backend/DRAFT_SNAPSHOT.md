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

readSnapshot giữ household lock, kiểm tra revision hiện tại, ngày/trạng thái kỳ và
metadata/payload tham số hiện tại. Nếu khác, stale=true. Thay Ledger ngoài khoảng kỳ
vẫn có thể đánh dấu stale: đây là kiểm tra bảo thủ theo household. OCR chưa xác nhận
không thay Ledger nên không làm stale totals đã ghi sổ; xác nhận OCR thì có.
Sau khi đọc xong transaction, writer có thể tiếp tục: trạng thái freshness chỉ đúng tại
thời điểm kiểm tra. Snapshot nháp không phải bản đóng băng/bằng chứng bất biến Ledger.

Không hỗ trợ sửa revision thủ công, tắt trigger hay TRUNCATE Ledger trong vận hành
runtime. Đây là thao tác DBA ngoài service; nếu bảo trì kiểu đó phải đánh dấu/rebuild
nháp có liên quan. Với batch nhiều household phải khóa theo thứ tự nhất quán và retry
deadlock/serialization khi có lỗi. Luồng xác nhận kỳ tương lai phải dùng cùng thứ tự khóa.

## SQL và áp dụng

Nguồn SQL duy nhất: `migrations/proposals/tax-draft-snapshot.sql`, **chưa cấp số**.
Bootstrap DB mới: baseline schema Ledger/Tax rồi cùng SQL proposal trong transaction.
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

Có thể làm tiếp ngay ba việc kỹ thuật trong PR nhỏ: phân trang danh sách snapshot
nội bộ, truy vấn freshness hàng loạt cho danh sách nháp, và mở rộng test concurrency
nhiều household. Không tự thêm endpoint, retention hay chính sách thuế.
