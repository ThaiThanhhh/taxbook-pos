# Báo cáo cá nhân gửi mentor Chung Zen

**Sinh viên:** Lê Hoài Bảo — GitHub 052205001004.
**Vai trò:** Backend Developer phụ trách Ledger & Tax, dự án TaxBook POS.
**Ngày chốt hồ sơ:** 06/11/2026. Đây là báo cáo đã chuẩn bị, chưa tự gửi mentor.

## 1. Nhiệm vụ và mức độ hoàn thành

Theo README, em phụ trách sổ doanh thu/chi phí, đối soát và mô-đun tính thuế theo bộ
tham số có phiên bản; Tax README còn bao gồm tính/chốt kỳ, tờ khai, nhắc hạn và báo cáo.

Em đã hoàn thành phần nền tảng Ledger và Tax nháp có thể kiểm thử/demo độc lập, tích
hợp trên NestJS của Quang Dũng, gom đủ lịch sử PR #7–#9 vào PR #6 và đồng bộ nền Dũng
f09690d bằng merge commit 4499d54. Em chưa tuyên bố hoàn thành nghiệp vụ thuế chính
thức hoặc toàn bộ API Tax/Reports của dự án; các phần phụ thuộc còn mở được liệt kê
trong [ma trận yêu cầu](REQUIREMENTS_STATUS.md). Em đã đối chiếu cả SRS v1/backlog/UAT
dự thảo trên nhánh BA 0119d73, dù các file này chưa nằm trong nhánh tích hợp.

Kết luận đề nghị nghiệm thu: phần kỹ thuật nháp đã đủ hồ sơ bàn giao và trình bày
mentor; cần Dũng/Tấn Tài xác nhận bằng tài khoản thật, chưa có approval thay người review.

## 2. Chức năng đã phát triển

- Ghi Ledger từ sale accepted qua SalesLedgerPort, dùng chung transaction caller;
  chống ghi trùng, giữ ngày bán gốc và rollback cùng caller khi lỗi.
- Chi phí manual/OCR draft; chỉ confirm OCR mới ghi sổ; idempotency, household scope
  và khóa kỳ đã được kiểm thử.
- Hủy sale bằng bút toán đảo, giữ bản gốc và retry an toàn; nhập CSV, validate và
  chống import trùng; gợi ý khớp và xác nhận/bỏ khớp, bảo vệ liên kết thuộc kỳ khóa.
- Tổng hợp POSTED revenue/expense theo range/ngày/tháng, không đếm CASH/BANK hai lần;
  xử lý tiền integer VND, kiểm tra overflow và phân trang.
- Bộ nạp tham số có version/ngày hiệu lực, kiểm tra APPROVED, core số học chính xác
  cho ví dụ DEMO; API đọc params/kỳ. Không suy ra taxable bases hoặc luật thuế chưa duyệt.
- Persist Tax Draft Snapshot PostgreSQL, dedup, đọc bằng pool mới, revision trigger
  transactional, stale reasons, keyset microsecond và batch freshness một SELECT.
- Migration rehearsal có history/checksum/lock/transaction/rollback, legacy upgrade,
  test prefix 12 migration; demo end-to-end chạy lại bằng schema test riêng.

## 3. Công nghệ và bằng chứng kiểm thử

Node.js >=22, TypeScript, NestJS 12; PostgreSQL/pg Pool, SQL constraints/trigger và
transaction; class-validator/class-transformer, JWT/jsonwebtoken, csv-parse;
Jest + node:test, PGlite cho chế độ embedded, GitHub Actions/PostgreSQL 16, oxlint.
Core số học dùng BigInt; không nhân trực tiếp số tiền bằng float để tính rounding.

Implementation đã kiểm thử: [4499d5418a0037ab3869448f8b35557a7be9a779](https://github.com/ThaiThanhhh/taxbook-pos/commit/4499d5418a0037ab3869448f8b35557a7be9a779).
Các commit tài liệu đóng gói sau đó không đổi runtime; xem [Checks HEAD hiện hành](https://github.com/ThaiThanhhh/taxbook-pos/pull/6/checks).

| Kiểm tra | Kết quả trên implementation 4499d54 |
| --- | --- |
| npm ci, build, lint | PASS |
| PostgreSQL local 17.10 | 41/41 (1 Jest + 40 node:test), không skip |
| Migration rehearsal | 3/3 PASS, gồm legacy upgrade/rollback và 12 migration |
| Ledger demo | PASS; trên CI chạy hai lần |
| Production audit | 0 vulnerabilities; full dev audit còn 26 cảnh báo đã ghi nhận |
| CI Node 22/PostgreSQL 16 | [PR SUCCESS](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215866913), [push SUCCESS](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215862263) |

Demo cho household A: revenue 150000 VND, expense 50000 VND, 5 relevant entries.
Đóng app/pool rồi đọc snapshot từ PostgreSQL vẫn giữ tổng tiền; sửa note không đổi
tiền làm revision 8→9 và stale. Household B vẫn fresh; các thao tác chéo hộ bị chặn.
Đây là terminal demo có assertions, không phải demo UI mobile hoặc OCR extraction.

## 4. Commit và Pull Request minh chứng

| Commit/PR | Công việc |
| --- | --- |
| a895274 / [#6](https://github.com/ThaiThanhhh/taxbook-pos/pull/6) | NestJS integration Ledger & Tax |
| 973b49c / [#7](https://github.com/ThaiThanhhh/taxbook-pos/pull/7) | Hardening old-match/validation/rollback và regression |
| cd69727 / [#8](https://github.com/ThaiThanhhh/taxbook-pos/pull/8) | Aggregation và đầu vào kỳ |
| 5d551a6, 8ae826d / [#9](https://github.com/ThaiThanhhh/taxbook-pos/pull/9) | Persistence/revision/listing/batch freshness |
| ae9ffb9, e644e61 | Rehearsal/demo và fix history ordering với 12 migration |
| 0b3f8a5 → 78635f3 → 4d5fec1 | Merge #9→#8→#7→#6, giữ đủ parents/đóng góp |
| 9ea0d80 | Bộ nghiệm thu, mentor demo và integration requirements |
| 4499d54 | Merge nền Dũng f09690d, xử lý package/lockfile/env conflicts |

PR #6 hiện Ready, chưa merge; requests tới NguyenQuangDung0309/Taiphan05, reviews
chưa có. #5 của Dũng vẫn Draft/OPEN, chưa có CI và chưa merge. Em không sửa #5/main,
không tạo PR mới hoặc force-push. Mobile sau đồng bộ giống nhánh Dũng.

## 5. Khó khăn và cách xử lý

- Hai nền backend có package/bootstrap/config khác nhau: giữ NestJS skeleton của Dũng,
  thống nhất module/transaction, giữ Jest gốc và sửa tương thích TS6/Nest12 ở PR tích hợp.
- Sai lệch khóa đối soát khi đổi liên kết: bảo vệ cả old/new ledger dates và thêm regression.
- Aggregate digest không phát hiện sửa giữ nguyên tổng tiền: thêm revision trigger cùng
  transaction, read freshness nhất quán và test rollback/equal-total edits.
- SQL history ORDER BY id đặt migration 10 trước 2: kiểm tra tập ID tạo prefix của
  plan và bổ sung regression 12 migration, replay, gaps và checksum mismatch.
- Nền Dũng cập nhật driver/env và nhận main: merge giữ lịch sử; hòa giải ba file
  package/lockfile/env, giữ Ledger scripts và DB_*; không chỉnh mobile hoặc Sales.
- Chưa có BR thuế đã duyệt và Sales thật: dùng Fake Sales/DEMO và ghi rõ phần thiếu,
  không viết luật thuế hoặc nhận dữ liệu nháp là nghĩa vụ chính thức.
- SRS/backlog BA còn yêu cầu tự đối soát ≥80%, cảnh báo ngưỡng và nhiều API Tax/Reports
  chưa có; em không đánh dấu hoàn tất các UAT đó. JSON v1-draft khác schema loader
  hiện tại (ngày hiệu lực, pit_methods, pit_ratio); đã tái hiện bị từ chối và ghi là
  dependency cần thống nhất, chưa tự đổi loader hoặc áp dụng brackets/luật mới.

## 6. Công việc còn chờ nhóm và đề nghị xác nhận

**Dũng:** review backend/SQL/transaction; cung cấp Sales/Auth/Household contracts và
chọn shared client hoặc outbox; chuẩn hóa migration production; CI/review/merge hợp lệ #5.
**Tấn Tài:** review CI/tests, chạy/quan sát demo lặp và ghi run/SHA vào phiếu nghiệm thu.
**BA/Ngọc Thái:** SRS/BR, approved params và quy tắc bases/ngưỡng/làm tròn/phân bổ,
PROFIT_15, chốt/điều chỉnh kỳ, mẫu sổ/tờ khai, report semantics và lịch nhắc hạn.
**Nhóm mobile/AI:** tích hợp UI/OCR thật theo contract của từng thành viên; em chưa
nghiệm thu thay các phần này.

Em đề nghị mentor xem [demo 3 phút](MENTOR_DEMO.md), [checklist/sign-off](ACCEPTANCE.md)
và [đầu vào tích hợp](DUNG_INTEGRATION.md). Hồ sơ có thể bàn giao ngay; full Tax business
scope và việc merge main vẫn chưa hoàn tất. Sau #5 merge, cần retarget #6, kiểm tra
diff/conflicts/CI/approval/protection lại trước merge main.
