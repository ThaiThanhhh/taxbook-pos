# Backend Ledger & Tax — Lê Hoài Bảo

NestJS + PostgreSQL. Bản nền tảng tuần 1–2; chưa phải toàn bộ backend của nhóm.
Chọn driver `pg` trực tiếp vì main và nhánh Sales chưa có ORM/code nền. Các module
Nest có thể đưa vào ứng dụng chung khi Quang Dũng bổ sung Sales/Auth.

## Chạy trên máy

Yêu cầu Node.js 22 trở lên, PostgreSQL 16. Từ thư mục gốc repo:

```powershell
docker compose up -d postgres
cd backend
npm ci
Copy-Item .env.example .env
```

Trong `backend/.env`, đặt `DATABASE_URL` trỏ tới database phát triển riêng và thay
`JWT_SECRET` bằng chuỗi ngẫu nhiên ít nhất 32 ký tự. Không dùng database có dữ liệu thật.
Nếu không dùng Docker, tạo database PostgreSQL riêng rồi cấu hình URL tương ứng.

```powershell
npm run db:bootstrap
npm start
```

Bootstrap **chỉ chạy trên public schema trống**, tạo bảng trong một transaction,
không chạy tự động khi khởi động server và không nạp/duyệt tham số thuế.
Các file `src/modules/{ledger,tax}/schema.sql` là đề xuất schema cho database local.
Trước khi triển khai database nhóm, Quang Dũng phải cấp số migration và review cách
liên kết với bảng Sales/Household. Không tự áp dụng bootstrap vào database nhóm.

API ở `http://127.0.0.1:3000/api/v1`. Để phát triển, chạy `npm run build` sau khi
sửa source; `npm run dev` chỉ theo dõi output trong `dist/`.

## Thử một luồng

Chưa có `/auth/login`: module này xác minh JWT HS256 đã được ký, có `exp`, issuer,
audience, `household_id` và role `OWNER`, `ACCOUNTANT` hoặc `ADMIN`.
Không lấy household từ request body hay header tự đặt. STAFF chưa được truy cập
Ledger & Tax. Cần chốt lại ma trận quyền với BA khi tích hợp Auth chung.

Tạo token local (15 phút, không dùng ở production):

```powershell
$demoJwt = (npm run token:demo --silent -- demo-household).Trim()
$demoHeaders = @{ Authorization = "Bearer $demoJwt"; 'Idempotency-Key' = [guid]::NewGuid().ToString() }
$demoExpense = @{ date = '2026-10-30'; amount_vnd = 125000; category = 'supplies'; source = 'MANUAL' } | ConvertTo-Json
Invoke-RestMethod http://127.0.0.1:3000/api/v1/expenses -Method Post -Headers $demoHeaders -ContentType 'application/json' -Body $demoExpense
Invoke-RestMethod http://127.0.0.1:3000/api/v1/ledger -Headers @{ Authorization = "Bearer $demoJwt" }
```

Gửi lại cùng `Idempotency-Key` và body sẽ nhận cùng response, không tạo thêm chi phí.
Đổi body nhưng giữ key sẽ trả 409. Key được tách theo hộ và thao tác.

Đổi `source` thành `OCR`, dùng key mới: bản nháp chưa có bút toán. Gọi
`POST /expenses/{expense_id}/confirm` với key mới để ghi sổ.
Chi phí MANUAL được ghi sổ ngay; OCR luôn chờ xác nhận.

## Đã triển khai

| API | Hành vi |
| --- | --- |
| `GET /ledger` | Lọc book/from/to, phân trang cursor ổn định, limit 1–200 |
| `POST /expenses` | Validation, idempotency, transaction, ghi tay/OCR |
| `POST /expenses/{expense_id}/confirm` | Xác nhận và ghi sổ đúng một lần |
| `POST /bank-statements/import` | Multipart field `file`, CSV tối đa 1 MiB/5000 dòng |
| `GET /bank-statements/matches` | Phân trang; chỉ gợi ý khi có đúng một bút toán BANK cùng ngày/số tiền |
| `POST /bank-statements/{line_id}/match` | CONFIRM/UNMATCH; không khớp chéo hộ hoặc dùng lại bút toán đã khớp |
| `GET /tax/params?as_of=YYYY-MM-DD` | Chỉ trả bộ APPROVED có người duyệt và ngày hiệu lực phù hợp |

CSV mẫu dùng header cố định:

```csv
txn_date,amount_vnd,description
2026-10-30,90000,Demo transfer
2026-10-30,-20000,Demo bank fee
```

Nhập lại **đúng cùng nội dung file** không thêm dòng; hai dòng giống nhau trong
một file vẫn được giữ. File bị sửa nội dung được xem là lần nhập khác; chưa có
mã giao dịch ngân hàng để khử trùng giữa các file khác nhau. Không tự động xác nhận
gợi ý khớp. Tất cả dữ liệu và truy vấn đều có `household_id`.

Tiền dùng số nguyên VND trong giới hạn chính xác JSON/JavaScript
±9,007,199,254,740,991; dữ liệu vượt giới hạn bị từ chối. Timestamp lưu UTC.
`entry_date` là ngày nghiệp vụ đã xác định, không tự chuyển từ giờ đồng bộ.

`book` hiện dùng mã kỹ thuật `REVENUE`, `EXPENSE`, `CASH`, `BANK`. Danh sách mẫu
sổ pháp lý như S1A/S2A và ánh xạ còn chờ BA xác nhận; chưa tuyên bố xuất sổ đúng mẫu.

## Ghép với Sales của Quang Dũng

Import `LedgerModule`, inject `LedgerService`. Không mở endpoint ghi doanh thu cho
mobile tự gọi. Ví dụ đầu vào service:

```typescript
await ledger.recordSale(householdId, {
  sale_id: persistedSale.id,
  entry_date: '2026-10-30', // ngày bán, không phải ngày đồng bộ
  amount_vnd: 90000,
  sector_code: 'GOODS_DISTRIBUTION',
  payments: [{ method: 'QR_TRANSFER', amount_vnd: 90000 }],
});
await ledger.reverseSale(householdId, persistedSale.id, 'Customer cancelled');
```

Gửi lại sale giống nhau không ghi trùng; cùng sale ID với dữ liệu khác trả conflict.
Hủy tạo bút toán âm theo ngày gốc, giữ nguyên bút toán gốc. Kỳ đã chốt chặn ghi mới,
xác nhận OCR, hủy đơn và thay đổi khớp sao kê có liên quan.

**Ranh giới transaction:** service tự commit transaction Ledger; chưa commit cùng
transaction Sales. Dũng cần ghi outbox cùng transaction Sales và retry việc ghi/hủy sổ,
hoặc cùng refactor để nhận transaction chung. Chỉ truyền đơn đã lưu thành công;
không đánh dấu tích hợp hoàn tất trước khi kiểm thử luồng outbox end-to-end.

Tương tự, mọi thao tác chốt kỳ tương lai phải lấy `lockHousehold` trong cùng transaction
với cập nhật trạng thái kỳ để tránh đua với ghi sổ. Không cập nhật kỳ trực tiếp bằng SQL
trong runtime. Hiện chưa có API chốt kỳ.

## Thuế: phần làm được và phần cần xác nhận

File `config/tax/tax-params.v0.json` vẫn là `DRAFT_UNVERIFIED`, không thay đổi.
Vì vậy `GET /tax/params` hiện trả **404 — chưa có bộ đã duyệt**, thay vì biến bản nháp
thành dữ liệu chính thức. File lỗi trả 503; bộ đã duyệt chồng ngày bị từ chối.
Không có endpoint duyệt tham số trong đợt này.

`calculateTax` là hàm thuần, dùng số nguyên/rational để nhân tỷ lệ và làm tròn.
Caller phải cung cấp **cơ sở tính GTGT, cơ sở tính TNCN đã xác định theo chính sách**
cho từng ngành và chọn FLOOR/HALF_UP rõ ràng. DEMO giữ nhãn nháp; OFFICIAL từ chối
tham số chưa duyệt. Hai phép tính trong test chỉ minh họa phép nhân trên cơ sở tính
giả lập, không phải xác định nghĩa vụ thuế.

Chưa tự suy đoán: ngưỡng doanh thu năm, cách phân bổ nhiều ngành, kỳ khai, cách chọn
làm tròn theo pháp lý hoặc phương pháp `PROFIT_15` (config chưa có đủ tham số).
Chưa triển khai API tính/chốt kỳ, tờ khai PDF, báo cáo và nhắc hạn. Các phần này phải
bám BR/SRS do Ngọc Thái xác nhận; không dùng engine số học như engine thuế hoàn chỉnh.

## Kiểm thử và bàn giao

```powershell
npm test
npm audit --omit=dev --audit-level=moderate
```

Mặc định test chạy HTTP Nest thật với PGlite (PostgreSQL nhúng), không mock câu SQL.
Để kiểm tra cả pg Pool và server PostgreSQL thật, đặt `TEST_DATABASE_URL` tới database
**riêng, trống, dùng một lần**, rồi chạy `npm test`. Test từ chối database có bảng và
không tự xóa bảng sau khi chạy. Không đặt URL database nhóm vào biến này.

CI chạy cả hai chế độ, gồm PostgreSQL 16. Nhờ Quang Dũng review các file nền tảng
backend và đề xuất schema; Tấn Tài review test/CI; Ngọc Thái xác nhận chính sách thuế.
Chưa có mã FR/BR chính thức trong SRS hiện tại nên không tự đặt mã yêu cầu.

Thứ tự tiếp theo: chốt migration + Auth/Sales outbox → BA duyệt BR thuế → API kỳ
thuế/chốt kỳ → báo cáo/tờ khai/nhắc hạn → demo E2E với mobile và QA.
