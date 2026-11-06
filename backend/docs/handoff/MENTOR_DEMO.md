# Demo Ledger & Tax trước mentor Chung Zen — 3 phút

Bằng chứng cập nhật 06/11/2026: implementation `4499d54`, [PR CI SUCCESS](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215866913)
và [push CI SUCCESS](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215862263).
Xem [báo cáo cá nhân](PERSONAL_REPORT_VI.md) và [phân loại yêu cầu](REQUIREMENTS_STATUS.md).
HEAD tài liệu mới hơn phải được đối chiếu với Checks của PR #6.

## Chuẩn bị trước buổi trình bày

Checkout HEAD mới nhất của PR #6. Trong `backend`, dùng Node >=22 và PostgreSQL test.
Tạo database test theo [hướng dẫn setup](../../DEMO_HANDOFF.md); không dùng DB nhóm.
Ví dụ dưới đây dùng container local đã chuẩn bị theo hướng dẫn đó:

```powershell
$env:TEST_DATABASE_URL='postgresql://dt13:local-test-only@127.0.0.1:55432/ledger_test'
npm ci --no-fund
npm run test:migrations
npm run demo:ledger
```

Chạy thử trước buổi demo, chỉ trình bày khi exit 0 và JSON `result: PASS`.
Không cần JWT hoặc API server riêng: script tự tạo JWT test, bind HTTP loopback/port
ngẫu nhiên, tạo schema test và đóng app/pools/cleanup. Không in credentials ra màn hình.

## Kịch bản nói và chỉ vào kết quả

| Thời gian | Lời trình bày gợi ý | Chỉ vào bằng chứng |
| --- | --- | --- |
| 0:00–0:25 | “Em là Lê Hoài Bảo, phụ trách Ledger & Tax, tích hợp lên NestJS của Dũng. Hôm nay em demo sổ và snapshot nháp.” | PR #6 và HEAD; #7–#9 đã gom bằng merge commits |
| 0:25–1:00 | “Fake Sales ghi doanh thu và Ledger trong cùng transaction. Retry không ghi trùng; caller lỗi rollback cả hai. Hủy giữ bản gốc và thêm reversal.” | `steps`: shared transaction/retry/rollback và cancellation |
| 1:00–1:35 | “Chi phí tay 20000 vào sổ ngay; OCR 30000 chỉ vào sau confirm. CSV được đọc từ file, import lại không trùng và đối soát cần xác nhận.” | `steps`: expense/OCR và CSV reconciliation |
| 1:35–2:15 | “Tổng hộ A là revenue 150000, expense 50000, 5 dòng REVENUE/EXPENSE kể cả reversal. CASH/BANK không cộng hai lần. Snapshot lưu PostgreSQL và đọc lại sau đóng app/pool.” | `totals`, `snapshot_id`, new-pool step |
| 2:15–2:45 | “Sửa note không đổi tiền vẫn làm snapshot stale, revision 8→9. Hộ B riêng vẫn fresh; không đọc hoặc confirm chéo hộ.” | `source_revision: 8`, `current_revision: 9`, isolation step |
| 2:45–3:00 | “Build/lint, PostgreSQL 41 test, rehearsal 3 test và production audit đã đạt. CI xanh; còn review và dependency Sales/Auth/Household/migration từ Dũng.” | [checklist/bằng chứng](ACCEPTANCE.md), Checks HEAD hiện hành |

Các kiểm tra nằm trong assertions của script, không phải màn hình UI tương tác. Chỉ
khẳng định các bước script đã PASS; CSV match/expense dùng HTTP thật, Fake Sales và
snapshot dùng service nội bộ. OCR ở đây là xác nhận dữ liệu nháp, chưa chứng minh AI OCR.

Nếu mentor yêu cầu chạy lại: `npm run demo:ledger`; mỗi run dùng schema sạch mới.
Snapshot ID trong log không còn truy vấn được sau cleanup. Nếu exit khác 0, dừng trình
bày kết quả thành công và dùng error/assertion để xử lý; không chuyển sang DB nhóm.

## Chốt phần chưa hoàn thành

Snapshot luôn DRAFT, official=false, tax_result=null; không trình bày tổng Ledger là
nghĩa vụ thuế, lợi nhuận kế toán hoặc cashflow. Sales thật/Household/Auth và production
migration chờ Dũng; luật thuế/chốt kỳ/tờ khai/báo cáo chờ BA. #5 chưa merge nên #6 chưa
vào main. Đã chuẩn bị nội dung báo cáo này, chưa tự gửi cho mentor.
