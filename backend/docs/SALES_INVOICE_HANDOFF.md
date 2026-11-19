
# TaxBook POS — Sales & Invoice Backend Handoff

## 1. Tổng quan

Phụ trách: Backend Sales & Invoice

Công nghệ:
- NestJS và TypeScript
- PostgreSQL
- Docker Compose
- Jest
- Mock Invoice Provider

Nhánh phát triển:
`feature/QDung-backend-sales-invoice`

## 2. Sales Module

Các phần đã triển khai:
- Lưu đơn bán và chi tiết thanh toán.
- Kiểm tra dữ liệu đơn bán.
- Chống trùng đơn khi đồng bộ.
- Xử lý batch đơn bán.
- Tích hợp ghi doanh thu với Ledger.
- API xem chi tiết đơn bán có xác thực JWT.
- Kiểm tra quyền truy cập theo hộ kinh doanh.

Lưu ý:
- Việc ghi Sales và Ledger sử dụng transaction.
- API đồng bộ từ chối xử lý khi thiếu dữ liệu
  kế toán đáng tin cậy từ Backend.
- Catalog và nguồn mã ngành cần được hoàn thiện
  trước khi mở luồng đồng bộ thực tế.

## 3. Invoice Module

Các phần đã triển khai:
- Mock Invoice Provider.
- InvoiceRepository.
- InvoiceOutboxRepository.
- Hàng đợi phát hành hóa đơn.
- Trạng thái PENDING, PROCESSING, RETRY,
  ISSUED và FAILED.
- Cơ chế lease và chống hai worker lấy cùng job.
- Giới hạn tối đa 5 lần thử.
- Worker xử lý một yêu cầu mỗi lần gọi.
- InvoiceModule được đăng ký vào NestJS.
- CLI chạy thử Invoice Worker.

## 4. Quy trình phát hành

1. Đơn bán được lưu thành công.
2. Tạo yêu cầu PENDING trong invoice_outbox.
3. Worker nhận yêu cầu và chuyển PROCESSING.
4. Gọi Mock Invoice Provider.
5. Thành công: lưu invoices và chuyển ISSUED.
6. Lỗi tạm thời: chuyển RETRY.
7. Đủ 5 lần thất bại: chuyển FAILED.

Mã invoice_id được giữ cố định khi thử lại.

## 5. Kiểm thử

Đã kiểm tra:
- Unit test Invoice: 25 PASS.
- Integration test InvoiceRepository: 4 PASS.
- Integration test InvoiceOutbox: 14 PASS.
- Dependency Injection InvoiceModule: 1 PASS.
- Worker CLI phát hành thành công trên database
  thử nghiệm taxbook_sales_test.

Lưu ý: Integration test yêu cầu DATABASE_URL
và cấu trúc database thử nghiệm phù hợp.

## 6. Các lệnh kiểm tra

Trong thư mục backend:

    npm run build

    npm run test:unit -- src/modules/invoice

Integration test cần nạp .env:

    node --env-file=.env --experimental-vm-modules node_modules/jest/bin/jest.js --runInBand --runTestsByPath src/modules/invoice/invoice-outbox.repository.integration.spec.ts

Worker CLI:

    node --env-file=.env dist/modules/invoice/invoice-worker.cli.js

CLI chỉ hỗ trợ PostgreSQL local và sử dụng
database taxbook_sales_test.

## 7. Giới hạn hiện tại

- Invoice Provider chỉ là Mock, chưa kết nối
  nhà cung cấp hóa đơn điện tử thực tế.
- Worker chưa chạy tự động theo lịch.
- Chưa tích hợp đầy đủ UI Flutter với Backend.
- Catalog cần cung cấp mã ngành kế toán tin cậy.
- Invoice Outbox mới được triển khai trong
  database thử nghiệm.
- Migration production chưa được phê duyệt.
- Chưa kiểm chứng toàn bộ hệ thống end-to-end.
- Cần cơ chế idempotency được nhà cung cấp
  hóa đơn thực tế hỗ trợ.

## 8. Việc cần làm tiếp

- Thống nhất schema production với nhóm.
- Hoàn thiện Catalog và kế toán.
- Kết nối Sales, Invoice và Flutter.
- Thiết kế cơ chế chạy Worker theo lịch.
- Bổ sung logging, monitoring và cấu hình bảo mật.
- Tích hợp nhà cung cấp hóa đơn thật.
- Kiểm thử end-to-end trước khi triển khai.

## 9. Lưu ý an toàn

Không chạy migration thử nghiệm trên database
chính dt13 hoặc database production.

Không commit file .env hay thông tin bí mật.

Các thay đổi schema cần được review trước
khi merge vào main.
