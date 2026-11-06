# Rà soát Ledger & Tax — PR #6

Nguồn đã kiểm tra: PR #5 `d49bf4c`, PR #6 `a895274`. Hai PR vẫn mở và chưa có
commit mới khi fetch. Đã đọc controller/service/DTO, schema SQL, guard, database,
test Ledger/Tax và đối chiếu OpenAPI/README/CONTRIBUTING. Không sửa Sales/Invoice,
OpenAPI, config thuế, bootstrap hoặc dependency của Dũng trong đợt này.

## Standards

Không phát hiện thêm vi phạm cứng về quyền sở hữu thư mục, hợp đồng API hay quy tắc
thuế. Số dòng PR #6 vượt mức gợi ý do tích hợp nền tảng; PR sửa lỗi này có base PR #6
để chỉ review phần thay đổi nhỏ. Migration vẫn là đề xuất chưa cấp số.

## Spec

- P1: CONFIRM có thể thay liên kết đối soát tới bút toán thuộc kỳ đã chốt. Đã sửa
  bằng kiểm tra liên kết cũ trước cả CONFIRM/UNMATCH; kiểm tra bút toán mới vẫn giữ.
  Test chứng minh 409 PERIOD_LOCKED và liên kết cũ không thay đổi.
- P2: Sales caller không qua DTO HTTP: payments rỗng với tổng 0 được chấp nhận,
  payments null/sai kiểu hoặc reason sai kiểu gây TypeError. Đã thêm runtime
  validation trước ghi SQL và hợp đồng TypeScript `SalesLedgerPort`.
- P2: khi ROLLBACK thất bại, code cũ trả connection về pool và làm mất lỗi gốc.
  Giờ loại connection lỗi khỏi pool, giữ lỗi nguyên nhân; có test lỗi kết nối giả lập.
- Giới hạn 1 MiB trước đây chỉ ở multipart, có thể bị bỏ qua khi gọi parser nội bộ.
  Giờ parser cũng kiểm tra byte size; không thay giới hạn hiện có.

Kết quả review: Standards không có vi phạm cứng mới; Spec có hai lỗi trực tiếp ở
đối soát và hợp đồng Sales, đã sửa. Lỗi pool và giới hạn parser được sửa khi kiểm tra
đường lỗi/database. Không refactor nghiệp vụ hay suy đoán quy tắc thuế.

## Bảo mật (NestJS trên Express)

### SEC-01 — High, đã sửa

`src/modules/ledger/bank.service.ts:76–81`: thay liên kết trước đây bỏ qua kỳ của
bút toán cũ, cho phép người có quyền đối soát thay đổi liên kết thuộc kỳ CONFIRMED.
Mọi thao tác thay/bỏ match giờ kiểm tra cả liên kết cũ trong transaction giữ khóa hộ.

### SEC-02 — Medium, đã gia cố

`src/modules/ledger/bank.service.ts:10`: parser CSV trực tiếp trước đây không có
giới hạn byte như endpoint multipart. Thêm cùng giới hạn 1 MiB trước parse; test HTTP
và gọi parser trực tiếp. Không ghi file upload xuống ổ đĩa hoặc tin tên file/MIME.

### Kiểm tra đạt và giới hạn triển khai

- Guard pin HS256, xác minh issuer/audience/expiry, household không rỗng và role;
  test thêm chữ ký sai, sai issuer/audience, thiếu exp/household. Không lấy household
  từ body. Không mở quyền mới hoặc xem ADMIN là quyền truy cập mọi hộ.
- Truy vấn SQL dùng tham số; composite FK và unique giữ bank match cùng hộ và một-một.
  Guard từ chối STAFF theo quy ước hiện có; ma trận quyền cuối cùng vẫn chờ nhóm chốt.
- Test lỗi database xác minh response không lộ SQL/hostname. Log production vẫn
  cần chính sách redaction và retention của nhóm; không dùng dữ liệu hộ thật trong test.
- Chưa phải xác nhận sẵn sàng public production: rate limit/edge proxy/TLS và vận hành
  Auth chung chưa nằm trong đợt sửa lỗi này. Hello World gốc vẫn public theo skeleton.

## Dependency: 26 cảnh báo development

Đánh giá từ `npm audit --json` trên lockfile hiện tại; không nâng/hạ dependency:

| Nhóm | Nguyên nhân và phạm vi |
| --- | --- |
| Jest/ts-jest và các package con | Phần lớn cảnh báo moderate/low lan truyền từ glob/minimatch, test-exclude và deepmerge. Có nguy cơ DoS khi xử lý pattern hoặc prototype poisoning khi merge cấu hình không tin cậy trong toolchain. Không nhận cấu hình/pattern từ người dùng API. |
| Nest CLI | minimatch có nguy cơ DoS khi xử lý glob; thuộc build/generate, không phải route Ledger. |
| Nest Mau | chuỗi inquirer → external-editor → tmp (high): ghi file tạm qua symlink/path traversal; undici (high): nhiều advisory HTTP/WebSocket/TLS. Mau là công cụ deploy dev, không được import vào module runtime. |

Tổng 6 low, 18 moderate, 2 high là số package bị gắn cờ (có lan truyền), không phải
26 lỗ hổng độc lập trong API. `npm audit --omit=dev` trả 0 tại thời điểm rà soát.
Điều này không chứng minh toàn ứng dụng không có lỗ hổng.

`npm audit fix --force` đề xuất thay major/hạ Jest 30 xuống 25, Nest CLI 12 xuống 11,
Mau xuống 0.0.x. Không áp dụng vì phá nền tảng nhóm. Đề xuất Dũng/Tấn Tài xử lý
toolchain trong PR riêng: ưu tiên patch tương thích đã kiểm chứng, cân nhắc bỏ Mau
nếu nhóm không dùng deploy; không chạy CLI/deploy với cấu hình hoặc repo không tin cậy.
Production nên build riêng rồi cài `npm ci --omit=dev`, chạy `node dist/main.js` với
biến môi trường đã cấp; `npm start` hiện dựa Nest CLI nên không dùng cho image chỉ có prod deps.

## Đề xuất migration PostgreSQL, chưa cấp số/chưa áp dụng DB nhóm

- Giữ bảng/constraints trong `src/modules/{ledger,tax}/schema.sql` là bootstrap
  **database local trống**. Chưa phải migration triển khai database có dữ liệu.
- Thêm index đề xuất `bank_statement_page_idx(household_id, txn_date, id)` khớp
  truy vấn ORDER BY/cursor; giữ unique import và matched_ledger_id hiện có.
- Với DB đã tồn tại, Dũng cấp số migration mới để tạo index. Không sửa migration
  đã merge. Cân nhắc CREATE INDEX CONCURRENTLY ngoài transaction theo runner nhóm.
- Composite FK `(household_id, matched_ledger_id)` → ledger cùng hộ và unique match
  đã đúng; không cascade xóa bút toán hoặc lịch sử đối soát.
- Không tự thêm FK Household/Sales vì Dũng chưa xác nhận key/type/lifecycle.
  `ref_type/ref_id` là tham chiếu nghiệp vụ, không tự nhận là FK đã kiểm chứng.
- `param_set_id` tham chiếu bộ tham số, kỳ có DRAFT/CONFIRMED; chưa tự tạo trạng thái
  mới. Cần cơ chế bất biến phiên bản tham số, không cập nhật payload đã dùng khi BA
  chốt luồng duyệt/tính kỳ. Không đánh dấu đã hoàn thiện tính/chốt kỳ.
- Mọi writer/chốt kỳ phải giữ lockHousehold cùng transaction. Shared Sales client
  phải là transaction đang mở trên cùng DB, propagate lỗi để rollback; nếu không,
  dùng outbox. Không giữ transaction chờ mạng. Với batch nhiều hộ cần thứ tự khóa
  nhất quán; transaction REPEATABLE READ/SERIALIZABLE phải retry lỗi serialization.

## Test và điều kiện merge

Giữ 20 bài cũ, thêm 9 bài: old-match lock, dữ liệu Sales sai + race revenue,
HTTP/parser CSV limits, concurrent OCR, concurrent match, JWT claims, database
response, rollback khi write lỗi + retry cùng key, rollback mất kết nối.
CI dùng database PostgreSQL 16 disposable; local mặc định PGlite. Không dùng DB nhóm.
Local đã chạy lại từ `npm ci`: build/lint đạt, 1 Jest + 28 node:test đạt (tổng 29),
production audit 0 cảnh báo. Kết quả PostgreSQL 16 xem Actions của PR sửa lỗi.

PR #6 không nên merge nguyên trạng vì lỗi old-match lock. Sau khi đưa bản sửa này
vào nhánh tích hợp và CI xanh, có thể review merge nền tảng, với điều kiện Dũng duyệt
integration/schema và Tấn Tài duyệt test/CI. PR #5 phải merge trước hoặc xử lý base
theo quy trình nhóm. Chưa phải hoàn tất sản phẩm thuế hoặc E2E Sales.

Cần Dũng xác nhận: ID/key Household/Sales, migration runner/số thứ tự, transaction
hoặc outbox và ma trận quyền Auth. Cần Ngọc Thái xác nhận: cơ sở thuế theo kỳ/năm,
ngưỡng, phân bổ ngành, làm tròn, mẫu sổ, bất biến tham số và quy tắc điều chỉnh kỳ.
