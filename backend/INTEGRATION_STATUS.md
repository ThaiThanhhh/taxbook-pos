# Ledger & Tax — kiểm tra source và tích hợp ngày 01/11/2026

## Code của Quang Dũng

Đã đọc source nhánh `feature/QDung-backend-sales-invoice`, commit
`d49bf4c38badc84ce5a38a156fb7f1903492fb07` (PR #5 còn mở).
Có Nest CLI, NestJS 12, TypeScript 6, AppModule/AppController/AppService,
endpoint Hello World, bài test controller, Jest và oxlint.
Chưa có source nghiệp vụ Catalog/Sales/Invoice/Sync/Auth: các module còn README.
Chưa có driver database, ORM, entity, migration thực thi, luồng thanh toán hay outbox.
Không suy luận tính năng hoàn thành từ tên nhánh hoặc mô tả PR.

## Hai nhánh được hợp nhất thế nào

Nhánh mới tạo trực tiếp từ commit trên của Dũng; đưa module PR #4 sang có chọn lọc.
Các điểm xung đột: package/lockfile, tsconfig và main. Giữ Nest CLI, cấu trúc
AppModule, test Jest và lint của Dũng; bổ sung dependencies pg/validation/CSV/JWT.
Chỉ có main.ts gọi createApp; app.ts là factory dùng chung cho runtime và test.
Guard đặt ở controller Ledger/Tax, không đặt global để tránh chặn API thành viên khác.
Endpoint Hello World vẫn chạy (dưới /api/v1 do hợp đồng base URL chung).

Sửa rootDir cho TypeScript 6; Jest chạy ESM qua VM modules để đọc NestJS 12.
Giữ nguyên source và test AppController/AppService. Không sửa API/config thuế,
source Sales/Invoice/Catalog/Sync, migration của người khác, hoặc PR #4/#5.

## Hoàn thành trong phạm vi kỹ thuật

- Giữ API Ledger/Expense/OCR, idempotency, CSV, gợi ý/xác nhận đối soát và khóa kỳ.
- Doanh thu/hủy dùng service với dữ liệu sale giả lập; chưa tự viết Sales.
- recordSale/reverseSale nhận client transaction của caller để commit/rollback cùng Sales.
- Hủy có thứ tự đọc ổn định; kiểm thử rollback, chống ghi trùng và truy cập chéo hộ.
- GET /tax/periods lọc household, đúng DRAFT/CONFIRMED trong OpenAPI.
- Đọc cấu hình theo phiên bản/ngày; tính số học chính xác; chỉ DEMO khi chưa duyệt.
- Schema kỳ có param_set_id và kiểm tra giới hạn tiền; chưa chạy trên DB nhóm.

## Chưa thể hoàn thiện nghiệp vụ

SRS vẫn là README chỗ đặt tài liệu. Cấu hình là DRAFT_UNVERIFIED. Vì vậy không mở
API calculate/confirm, không tạo trạng thái CALCULATED/FINALIZED trái OpenAPI,
không suy diễn ngưỡng/cơ sở thuế/làm tròn. Chưa có báo cáo/tờ khai/nhắc hạn.
Chỉ schema chuẩn bị liên kết phiên bản; chưa có bản tính thuế chính thức được lưu.
Các schema SQL là đề xuất bootstrap local, không phải migration được cấp số.

Quang Dũng cần xác nhận: số migration, ID và schema Household/Sales, Auth/role chung,
cách truyền transaction hoặc outbox, nguồn ngày bán và xử lý hoàn/hủy đơn.
Ngọc Thái cần xác nhận: cơ sở tính theo kỳ/năm, ngưỡng, phân bổ ngành, cách làm tròn,
phương pháp PIT, quy trình duyệt tham số, ánh xạ mẫu sổ và quy tắc điều chỉnh kỳ đã chốt.
Tấn Tài cần review CI/test trước merge.

## Kiểm tra

`npm ci`, `npm run build`, `npm run lint`, `npm test` là lệnh kiểm tra của nhánh.
Test gồm bài Jest gốc của Dũng và 19 bài node:test (HTTP thật + PGlite).
CI chạy lại suite với PostgreSQL 16 disposable qua pg Pool; không dùng DB nhóm.
Audit production: không có cảnh báo tại thời điểm kiểm tra. Audit toàn bộ bao gồm
toolchain dev còn 26 cảnh báo (6 low, 18 moderate, 2 high); không ép nâng major
toolchain của Dũng trong PR tích hợp này. Xem CI để biết kết quả trên commit cuối.
