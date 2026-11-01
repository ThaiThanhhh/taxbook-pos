# Ledger & Tax — demo và bàn giao

Phạm vi: nháp đầu vào thuế của Lê Hoài Bảo, PR #9 stacked sau #5–#8.
Fake Sales chỉ là fixture, không phải Sales của Quang Dũng. Snapshot luôn DRAFT,
official=false, tax_result=null; demo không tính/chốt nghĩa vụ thuế.

## Chạy từ checkout sạch

Cần Node >=22, npm và PostgreSQL 16+ test riêng. Chạy từ thư mục `backend`.
Hai lệnh mới chỉ đọc `TEST_DATABASE_URL`, không tự đọc `.env` hoặc dùng `DATABASE_URL`.
Tên DB phải chứa thành phần `test` riêng, ví dụ `ledger_test`; không dùng DB nhóm.

PowerShell, với Docker daemon đang chạy (mật khẩu này chỉ dùng local test):

```powershell
docker run --name taxbook-handoff-test -e POSTGRES_USER=dt13 -e POSTGRES_PASSWORD=local-test-only -e POSTGRES_DB=ledger_test -p 127.0.0.1:55432:5432 -d postgres:16
docker exec taxbook-handoff-test pg_isready -U dt13 -d ledger_test
# Đợi accepting connections rồi tiếp tục.
$env:TEST_DATABASE_URL='postgresql://dt13:local-test-only@127.0.0.1:55432/ledger_test'
npm ci --no-fund
npm run test:migrations
npm run demo:ledger
npm run demo:ledger
```

Có PostgreSQL local thì tạo DB test mới và đặt URL tương ứng, không cần Docker.
Role cần CONNECT/CREATE schema và tạo table/function/trigger trong schema của mình.
HTTP chỉ bind `127.0.0.1`, port ngẫu nhiên, JWT tự sinh và không in secrets ra log.

Mỗi lần chạy tạo schema `taxbook_rehearsal_<uuid>` không có public trong search_path.
`finally` đóng app/pools rồi xóa đúng schema vừa tạo, kể cả assertion lỗi. Không
DROP DATABASE, TRUNCATE hoặc xóa bảng public/schema người khác. Chạy lại luôn bắt đầu
schema trống, kể cả suite cũ đã để bảng public. Process bị kill/power loss có thể để
schema mồ côi; DBA test kiểm tra, runner không quét/xóa schema của lần chạy khác.

Khi không cần container test trên nữa: `docker stop taxbook-handoff-test`, rồi
`docker rm taxbook-handoff-test`. Chỉ dùng tên container vừa tạo bằng lệnh trên.

## Luồng demo và kết quả mong đợi

1. Fake Sales lưu ACCEPTED và gọi Ledger cùng transaction; retry không ghi trùng.
   Caller lỗi rollback cả fake sale và Ledger.
2. HTTP tạo chi phí tay 20.000; retry cùng key trả cùng expense. OCR 30.000 chưa được
   cộng trước xác nhận; xác nhận hai lần chỉ ghi một lần, hộ khác nhận 404.
3. Hủy sale 50.000 bằng reversal cùng transaction Fake Sales; retry hủy an toàn,
   giữ bút toán gốc.
4. Đọc `tests/fixtures/demo-bank.csv`, upload multipart HTTP; import lại không trùng.
   Đọc suggestion và xác nhận match; hộ khác không match/đọc được line.
5. Tổng hộ A: revenue **150.000**, expense **50.000**, **5** dòng REVENUE/EXPENSE
   gồm reversal. CASH/BANK không cộng revenue lần hai. Hộ B riêng: revenue 990.000.
6. Tạo kỳ/snapshot DRAFT cho hai hộ; cùng đầu vào trả cùng ID.
7. Đóng toàn bộ app/pool rồi dùng pool/service mới đọc snapshot và SELECT row từ
   PostgreSQL: tổng tiền giữ nguyên, không phụ thuộc cache của app cũ.
8. Sửa note expense trong household lock/transaction: tổng không đổi, revision A
   **8 → 9**, snapshot stale với LEDGER_REVISION_CHANGED. Hộ B vẫn fresh; kiểm tra
   isolation qua read/prepare/freshness/list snapshot.

Thành công: exit 0 và JSON result=PASS, steps, totals, snapshot ID và revisions.
Lỗi bất kỳ: exit khác 0. ID chỉ là chứng cứ execution, snapshot được dọn khi thoát.

## Migration rehearsal

`src/rehearsal/migrations.ts` chỉ là runner test, không thay runner production.
Manifest dùng nguyên SQL hiện có; ID rehearsal-* chưa phải số migration nhóm.
SHA-256 chuẩn hóa CRLF/LF để checkout Windows/Linux có cùng checksum.

- Fresh: baseline Ledger → baseline Tax → snapshot persistence → index listing.
- Tracking: rehearsal_migration(id,checksum,applied_at); replay skip; checksum thay
  đổi hoặc history khác prefix thì fail.
- BEGIN → advisory transaction lock theo schema → tracking/DDL → COMMIT. Hai runner
  cùng schema không cùng áp dụng migration; toàn bộ pending commit cùng nhau.
- Dry rollback thực thi rồi ROLLBACK. Fault injection sau DDL chứng minh DDL/history
  đều rollback trên fresh và schema cũ, không để lại partial upgrade.
- Upgrade PR #8: baseline chưa có history, seed Ledger/kỳ, chỉ chạy hai proposal cuối.
  Giữ dữ liệu cũ, kiểm tra trigger revision và tạo/đọc snapshot của doanh thu cũ.
  History chỉ ghi hai proposal thật sự chạy, không giả nhận baseline đã được runner chạy.
- Không có destructive down sau COMMIT. Production rollback cần kế hoạch DBA riêng.

`npm run test:migrations` bắt buộc PostgreSQL thật, không skip/PGlite fallback.
CI PostgreSQL 16 chạy rehearsal và demo hai lần. Local bàn giao dùng PostgreSQL 17.

Kết quả local 01/11/2026 (Node 26.7.0, PostgreSQL 17.10): npm ci/build đạt, lint
không warning; npm test trên PostgreSQL đạt **41/41**, không skip; PGlite đạt
**40 pass + 1 skip** multi-connection; rehearsal **2/2** đạt, demo chạy lặp đạt.
Kiểm tra pg_namespace sau khi chạy: **0 schema rehearsal còn lại**. Không phát hiện
lỗi nghiệp vụ mới trong lượt này; không sửa code runtime Ledger/Tax hoặc SQL proposal.

## Kiểm tra toàn bộ

```powershell
npm run build
npm run lint
Remove-Item Env:TEST_DATABASE_URL -ErrorAction SilentlyContinue
npm test
npm audit --omit=dev --audit-level=moderate
npm audit
```

`npm test` mặc định PGlite, một bài multi-connection skip đúng thiết kế. Muốn chạy
suite đó trên PostgreSQL thật: dùng DB test mới với public trống, đặt TEST_DATABASE_URL
rồi npm test. Suite cũ từ chối public có bảng và không tự xóa dữ liệu; không chạy lặp
suite đó trên cùng DB đã dùng. Hai lệnh rehearsal/demo mới chạy lặp được nhờ schema riêng.

Audit production đạt 0. Full audit có 26 cảnh báo dev toolchain (6 low, 18 moderate,
2 high), exit 1; không gọi là audit toàn bộ xanh. Không audit fix --force để hạ/thay
major Jest/Nest trong phạm vi này. Dependencies/lockfile không đổi.

## Checklist review và merge

GitHub kiểm tra 01/11/2026: tất cả OPEN/DRAFT, MERGEABLE, reviews rỗng.
Đọc lại HEAD/checks trước merge; mergeable không phải approval.

| PR | Head trước cập nhật này | Base/dependency | Review |
| --- | --- | --- | --- |
| #5 | d49bf4c | main | NestJS skeleton của Dũng |
| #6 | a895274 | nhánh #5 | Integration/Auth/transaction |
| #7 | 973b49c | nhánh #6 | Fix khóa old-match, boundary và rollback |
| #8 | cd69727 | nhánh #7 | Tổng hợp và đầu vào kỳ |
| #9 | 8ae826d + commit bàn giao | nhánh #8 | Persistence/list/freshness, runner/demo |

- [ ] Dũng review backend, shared transaction/outbox, SQL và migration numbering;
  Tấn Tài review assertions/CI, PostgreSQL independent connections và upgrade.
- [ ] Diff không sửa Sales/Invoice; snapshot khác household không lộ ID.
- [ ] HEAD cuối đạt build/lint/tests, production audit, rehearsal và hai demo;
  xem full dev audit riêng.
- [ ] DBA review locks/index/backup/cửa sổ triển khai. Runner này chỉ cho test.
- [ ] BA/Ngọc Thái xác nhận phạm vi nháp, không tự bật nghiệp vụ thuế chính thức.
- [ ] Đề xuất giữ dependencies bằng merge commit **#9 vào #8 → #8 vào #7 → #7 vào #6**;
  sau mỗi bước kiểm tra HEAD/diff/checks/approval. Rồi #5 vào main, retarget #6 về main,
  review diff tổng đã có fix #7–#9 trước khi merge #6. Tránh triển khai integration
  thiếu fix #7. Chủ repo chọn chiến lược và thao tác merge/retarget.
- [ ] Không force-push, không tạo PR mới, không sửa lịch sử migration đã merge.

Lượt bàn giao này không merge bất kỳ PR nào. Checklist không phải ủy quyền merge.

## Chờ bên ngoài

Sales thật, Household keys/Auth chung, transaction hoặc outbox chờ Dũng. Thuế chính
thức, làm tròn/ngưỡng/phân bổ, chốt kỳ/tờ khai/báo cáo chờ BA duyệt. Migration nhóm,
số thứ tự và triển khai chờ DBA/Dũng. Không chặn demo nháp/review PR #9, nhưng chưa
đủ để tuyên bố Sales thật/thuế production sẵn sàng.
