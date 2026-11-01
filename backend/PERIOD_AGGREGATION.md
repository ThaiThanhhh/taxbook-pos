# Tổng hợp Ledger và dữ liệu kỳ thuế

Ghi chú mới: prepareSnapshot đã được mở rộng lưu DB; xem DRAFT_SNAPSHOT.md.
Các mô tả snapshot trong memory dưới đây ghi lại phạm vi ban đầu của PR #8.

Nhánh này dựa HEAD PR #7 `973b49c`, giữ toàn bộ hardening/test. Khi fetch, PR #5/#6/#7
vẫn mở và chưa có commit mới. PR #7 MERGEABLE, cả hai CI xanh nhưng là Draft,
reviews=[]; không merge khi chưa có review. Merge-base #7/#6 là `a895274`.

## Đã triển khai

- `LedgerSummaryService.range(household,{from,to},client?)`: tổng doanh thu và chi phí
  đã ghi sổ, khoảng ngày bao gồm cả hai đầu, số nguyên VND.
- `buckets(...,{by:'DAY'|'MONTH',limit,cursor})`: nhóm ngày/tháng tăng dần, cursor
  gắn household/range/granularity, limit 1–200. Tháng chỉ cộng phần nằm trong range.
  Không tự tạo dòng zero cho ngày không giao dịch; range trống trả tổng 0.
- Cộng REVENUE và EXPENSE, bao gồm bút toán âm của giao dịch hủy; không cộng CASH/BANK
  lần nữa. OCR chưa xác nhận không có bút toán nên không được cộng. Không suy diễn
  tổng chi phí thành chi phí được trừ thuế, hoặc doanh thu thuần thành cơ sở thuế.
- SUM(bigint) đọc numeric dạng text, kiểm tra BigInt trước chuyển JSON number;
  nếu tổng vượt safe integer thì trả lỗi thay vì làm tròn mất tiền.
- `TaxPeriodService.list`: phục vụ GET /tax/periods, giữ nguyên response OpenAPI,
  household và DRAFT/CONFIRMED. Không tạo endpoint mới.
- `prepareSnapshot(household,periodId)`: lấy household lock + row lock của kỳ,
  từ chối CONFIRMED, tổng hợp cùng client transaction. Kết quả nháp gồm totals,
  ngày kỳ, param_set_id/version/status nếu đã gắn, schema_version, digest và UTC timestamp.
  Luôn official=false, tax_result=null; không ghi số thuế hoặc đổi trạng thái kỳ.

Digest nhận diện dữ liệu tổng hợp, không phải bằng chứng danh sách từng bút toán
hoặc snapshot bất biến đã lưu. Sau khi transaction kết thúc, writer có thể thay dữ
liệu DRAFT; phải tính lại trong transaction chốt kỳ tương lai. Cursor ổn định theo
thứ tự bucket, không đóng băng dữ liệu giữa các trang khi có bút toán backdate.

## Snapshot và database

Chưa cần thay schema để đọc/tổng hợp. Index ledger_page_idx(household_id,entry_date,id)
đã hỗ trợ lọc kỳ; điều kiện ngày không bọc hàm, chỉ to_char ở GROUP BY tháng.
Giữ nguyên FK/unique/index đề xuất của PR #7; không cấp số hoặc chạy migration DB nhóm.
backend/migrations/README.md hiện chưa có runner/quy ước đánh số.

Khi BA chốt luồng tính/chốt kỳ: đề xuất migration mới thêm bảng snapshot append-only
liên kết period và household, source range, totals chính xác, digest, captured_at,
param_set_id + version/payload bất biến. Kiểm tra composite FK theo schema chung,
backfill/validation dữ liệu cũ trước ràng buộc mới; không dùng bootstrap trên DB có dữ liệu.
Không tạo bảng snapshot suy đoán rồi tự áp dụng trước khi vòng đời được xác định.

## Các phần chưa có đủ căn cứ

- Thuế chính thức/chốt kỳ: config/tax/tax-params.v0.json vẫn DRAFT_UNVERIFIED,
  filing_period=TO_BE_CONFIRMED. docs/srs và docs/tax-rules vẫn placeholder, chưa có BR.
  Engine DEMO hiện có được giữ nguyên. Test xác minh snapshot gắn tham số nháp vẫn
  không có kết quả thuế; API calculate/confirm chưa đăng ký (404), không cho chốt nháp.
- Reports: OpenAPI có DailyProfit bắt buộc profit_vnd nhưng chưa có quy tắc định
  nghĩa lợi nhuận. CASH/BANK phản ánh thanh toán sale và reversal, chưa có dữ liệu
  phương thức thanh toán chi phí; không dùng doanh thu trừ chi phí như lợi nhuận kế toán
  hoặc doanh thu như cashflow thực nhận. Chưa mở hai API báo cáo; summary service
  đã có thể tái sử dụng khi có quy tắc/data mapping, không sửa OpenAPI.
- Sales thật: nhánh Dũng d49bf4c vẫn skeleton, các module chỉ README, chưa có SalesService,
  payment schema/outbox. Giữ SalesLedgerPort, thêm fake Sales caller trong test dùng
  temporary marker và shared transaction; không quyết định schema Sales/Household.

Chỉ những phần trên đang thiếu căn cứ. Việc tổng hợp Ledger và chuẩn bị đầu vào kỳ
đã hoàn thành độc lập. Còn lại: review/merge chuỗi #7→#6 sau #5, tích hợp Sales thật,
migration runner/numbering, BR thuế, snapshot lưu bền, tính/chốt kỳ và Reports.

## Kiểm thử

Giữ 29 bài cũ. Thêm 5 bài: tổng hợp/range/bucket và OCR/hủy; overflow chính xác;
snapshot draft/confirmed/household/param version/API; snapshot vs writer/rollback;
fake Sales commit/rollback. CI chạy PGlite và PostgreSQL 16 disposable, không dùng DB nhóm.
Các lệnh: npm ci, npm run build, npm run lint, npm test. Xem checks commit cuối để
biết kết quả thực chạy. Không thay dependencies hoặc chính sách thuế.
