# Nghiệm thu và bằng chứng Ledger & Tax

Chủ phần việc: Lê Hoài Bảo (`052205001004`). Ngày kiểm tra GitHub: 06/11/2026.
Implementation đã đồng bộ/kiểm thử: [4499d5418a0037ab3869448f8b35557a7be9a779](https://github.com/ThaiThanhhh/taxbook-pos/commit/4499d5418a0037ab3869448f8b35557a7be9a779),
hai parent 9ea0d80 và f09690d. Các commit đóng gói tài liệu sau SHA này cần CI riêng.
Bộ tài liệu này bổ sung nghiệm thu, không thay đổi runtime, SQL hoặc quy tắc thuế.

Cập nhật tích hợp 06/11/2026: tác giả PR #6 xác nhận đưa cả nền NestJS của Dũng qua
PR này; PR #6 đã retarget từ nhánh Dũng sang **main**, không đợi #5 merge riêng.
Xác nhận phạm vi này không thay human review/approval. #5 vẫn được giữ nguyên.

Kết luận kỹ thuật: hoàn thành nền tảng Ledger & Tax nháp trong phạm vi demo đã kiểm
chứng, đủ hồ sơ bàn giao mentor; chưa hoàn thành toàn bộ nghiệp vụ Tax trong README/
OpenAPI, chưa có human acceptance hoặc approval. Phân loại từng yêu cầu và khoảng
trống ở [REQUIREMENTS_STATUS.md](REQUIREMENTS_STATUS.md); báo cáo cá nhân ở
[PERSONAL_REPORT_VI.md](PERSONAL_REPORT_VI.md).

## Checklist kỹ thuật

Các dấu x dưới đây ghi nhận kiểm chứng tự động đã PASS trên implementation SHA trên;
không thay chữ ký nghiệm thu hoặc approval của thành viên nhóm.

| Đạt | Hạng mục | Tiêu chí quan sát được | Bằng chứng |
| --- | --- | --- | --- |
| [x] | Fake Sales → Ledger | Sale ACCEPTED và Ledger dùng chung transaction; caller lỗi rollback cả hai | `fake Sales caller commits ledger on shared client and rolls back when caller fails`, demo |
| [x] | Chống ghi trùng | Retry sale trả duplicate, đổi payload bị conflict; expense/import/reversal retry không tạo thêm rows | Ledger integration tests, demo sale/expense/CSV/cancel retries |
| [x] | Chi phí/OCR confirmation | Manual được ghi ngay; OCR chưa xác nhận không vào tổng; confirm hai lần chỉ ghi một lần | `OCR draft stays outside ledger until confirmation; repeated confirmation is safe`, concurrent confirmations |
| [x] | Đối soát CSV | Parser kiểm tra headers/date/money/size; import lại không trùng; suggestion cần CONFIRM; old match kỳ khóa không bị tháo | CSV parser/import/limit tests, `replacement cannot unlink a bank entry in a confirmed period`, demo |
| [x] | Hủy giao dịch | Giữ bút toán gốc, reversal cân bằng, retry không ghi thêm | `sale cancellation creates balancing entries exactly once without deleting originals`, demo |
| [x] | Tổng hợp | Chỉ REVENUE/EXPENSE POSTED và reversals; CASH/BANK không cộng lần hai; overflow bị từ chối | summary/date boundaries/overflow tests, demo totals |
| [x] | Tax Draft Snapshot | Lưu DB, cùng đầu vào trả cùng ID; đóng app/pool rồi đọc từ pool mới; official=false, tax_result=null | snapshot persistence/insertion/confirmed-period tests, demo |
| [x] | Freshness | Sửa Ledger không đổi tổng vẫn stale; rollback không tăng revision; context kỳ/tham số đổi có lý do tương ứng | revision/rollback/bulk-context tests, demo revision 8→9 |
| [x] | Household isolation | Hộ B không đọc/xác nhận expense/match/snapshot hộ A; thay A không làm stale B | household API/snapshot tests, demo hai hộ |
| [x] | Listing/batch | Keyset không mất/trùng với 1.001 rows/microseconds; batch ≤200 một query | `snapshot keyset pages preserve microseconds/tied timestamps and bulk freshness uses one query` |
| [x] | Migration rehearsal | Fresh/replay/checksum/transaction/rollback/fault/concurrency/legacy upgrade; 12 migrations không phụ thuộc SQL order; từ chối public | 3 tests trong rehearsal suite |
| [x] | PostgreSQL integration | Pool thực, hai backend PID, concurrent snapshots/writers không mất cập nhật | `independent PostgreSQL connections create snapshots across households without lost updates`, CI PostgreSQL 16 |

Nguồn: [Ledger tests](../../src/modules/ledger/ledger.test.ts),
[Tax tests](../../src/modules/tax/tax.test.ts),
[migration tests](../../src/rehearsal/migrations.test.ts), [demo](../../src/rehearsal/demo.ts).

## Kết quả và cách kiểm tra lại

| Kiểm tra trên implementation 4499d54 | Kết quả đã ghi nhận |
| --- | --- |
| Build / lint | PASS / PASS |
| npm ci sau merge Dũng | PASS; lockfile khớp manifest, range @types/pg ^8.23.1 |
| PostgreSQL 17.10 local | 1 Jest + 40 node:test = **41/41**, không skip |
| Migration rehearsal | **3/3** PASS, gồm 12-migration regression và legacy upgrade |
| Ledger demo | PASS: revenue 150000, expense 50000, 5 relevant entries; revision 8→9 |
| Production audit | **0 vulnerabilities** |
| CI Node 22/PostgreSQL 16 | Push và PR SUCCESS, gồm PGlite, PostgreSQL, rehearsal, demo hai lần |

Từ thư mục `backend`, Node >=22 và PostgreSQL test riêng, đặt TEST_DATABASE_URL.
`npm test` trên PostgreSQL cần database test có public trống; không dùng DB nhóm.
Hai script rehearsal/demo dùng schema riêng và có thể chạy lặp trên cùng DB test.

```powershell
npm ci --no-fund
npm run build
npm run lint
npm test
npm run test:migrations
npm run demo:ledger
npm run demo:ledger
npm audit --omit=dev --audit-level=moderate
```

Chi tiết tạo DB, biến môi trường, PGlite fallback và cleanup:
[DEMO_HANDOFF.md](../../DEMO_HANDOFF.md). Không gọi PGlite là bằng chứng nhiều connection.
Nếu chỉ dùng PGlite thì test independent connections skip; PostgreSQL CI phải không skip.
Full dev audit đã biết có 26 warnings; production audit 0 không đồng nghĩa full audit xanh.

## Bằng chứng GitHub

| PR | Vai trò | Trạng thái lúc kiểm tra | Merge commit |
| --- | --- | --- | --- |
| [#5](https://github.com/ThaiThanhhh/taxbook-pos/pull/5) | NestJS Dũng, dependency | OPEN/Draft, f09690d, chưa checks/reviews | Chưa merge |
| [#6](https://github.com/ThaiThanhhh/taxbook-pos/pull/6) | Integration tổng hợp | OPEN/Ready, implementation HEAD 4499d54 | Chưa merge |
| [#7](https://github.com/ThaiThanhhh/taxbook-pos/pull/7) | Hardening | MERGED vào nhánh #6 | [4d5fec15ae63daf03e9ddcca2298ee13b4f10856](https://github.com/ThaiThanhhh/taxbook-pos/commit/4d5fec15ae63daf03e9ddcca2298ee13b4f10856) |
| [#8](https://github.com/ThaiThanhhh/taxbook-pos/pull/8) | Aggregation | MERGED vào nhánh #7 | [78635f310a9e91295e5d40b4ab17847e8f2af0d1](https://github.com/ThaiThanhhh/taxbook-pos/commit/78635f310a9e91295e5d40b4ab17847e8f2af0d1) |
| [#9](https://github.com/ThaiThanhhh/taxbook-pos/pull/9) | Snapshot/rehearsal/demo | MERGED vào nhánh #8 | [0b3f8a52f2c6ce0c81b87a966e36793509c97e37](https://github.com/ThaiThanhhh/taxbook-pos/commit/0b3f8a52f2c6ce0c81b87a966e36793509c97e37) |

- Implementation CI: [PR SUCCESS](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215866913),
  [push SUCCESS](https://github.com/ThaiThanhhh/taxbook-pos/actions/runs/42215862263), cùng SHA 4499d54.
- [Merge đồng bộ Dũng](https://github.com/ThaiThanhhh/taxbook-pos/commit/4499d5418a0037ab3869448f8b35557a7be9a779)
  giữ lịch sử, giải quyết ba conflict manifest/lockfile/env; mobile giống base Dũng,
  Ledger/Tax runtime và SQL không bị ghi đè.
- [Checks của HEAD PR #6 hiện hành](https://github.com/ThaiThanhhh/taxbook-pos/pull/6/checks):
  xem lại sau mọi commit tài liệu, source hoặc retarget; không dùng CI của SHA cũ thay cho HEAD mới.
- Commit gốc a895274, 973b49c, cd69727, 5d551a6, 8ae826d, ae9ffb9, e644e61 đều được
  giữ trong lịch sử. Merge dùng hai parents, không squash/rebase/xóa nhánh.

## Sign-off và điều kiện merge

- [ ] Dũng (`NguyenQuangDung0309`) review backend/integration/transaction/SQL trên HEAD cuối.
- [ ] Tấn Tài (`Taiphan05`) review test/CI và quan sát demo; ghi SHA/run đã nghiệm thu.
- [ ] Người nghiệm thu ghi tên, ngày, SHA và feedback; chưa có chữ ký trong bộ tài liệu này.
- [x] Tác giả xác nhận tích hợp chung nền #5 qua #6; #6 đã retarget main, chưa merge.
- [ ] Fetch main mới, kiểm tra diff/conflicts/CI/review trên HEAD/base main hiện hành.
- [ ] Khi #6 merge hợp lệ, xác minh f09690d và Ledger/Tax có trong main; kiểm tra #5 để tránh merge trùng, không tự đóng/xóa nhánh Dũng.
- [ ] Tuân thủ CONTRIBUTING.md và protection/rules hiệu lực tại thời điểm merge; không bypass.

Lúc kiểm tra: #5 chưa merge; #6 đã trỏ main, chưa có review, requested changes hoặc
unresolved threads; reviewers đã được yêu cầu. Giữ base main, chưa merge khi thiếu approval.
Main đang ở aad2661. Quy định CONTRIBUTING.md vẫn áp dụng; kiểm tra lại protection/
rules tại thời điểm merge, không suy ra quyền merge từ MERGEABLE. Không bật auto-merge.

### Phiếu xác nhận dùng trên GitHub hoặc buổi nghiệm thu

Người review tự điền từng ô và gửi bằng chính tài khoản của mình. Bản mẫu chưa ký:

| Người xác nhận | Phạm vi bắt buộc | SHA đã xem/test | Kết quả / link review |
| --- | --- | --- | --- |
| Dũng / NguyenQuangDung0309 | Backend, shared transaction, household lock, SQL, tương thích base f09690d | Chưa điền | Chưa xác nhận |
| Tấn Tài / Taiphan05 | CI, PostgreSQL thật, rehearsal/rollback/upgrade, demo/isolation | Chưa điền | Chưa xác nhận |
| Mentor Chung Zen nếu yêu cầu nghiệm thu | Quan sát demo, phạm vi cá nhân và phần còn chờ nhóm | Chưa điền | Chưa trình bày/ghi nhận |

Mẫu nội dung để reviewer copy vào GitHub, thay thông tin rồi tự submit review:

```text
Người xác nhận / vai trò:
PR #6 và HEAD SHA đã review:
CI/run hoặc lệnh đã quan sát:
Các mục checklist đã kiểm tra:
Kết quả: đạt phần nền tảng nháp / cần thay đổi (ghi rõ file, lỗi, cách tái hiện)
Giới hạn chấp nhận và dependency còn mở:
Ngày xác nhận / link review:
```

Nếu chọn Approve, dùng chức năng GitHub review; comment/phiếu demo không tự trở
thành approval hợp lệ. Mọi feedback lỗi phải có căn cứ; chưa có feedback không chứng
minh không còn lỗi. Review trên HEAD cũ phải được đánh giá lại khi HEAD/base thay đổi.

## Giới hạn nghiệm thu

Chỉ nghiệm thu nền tảng Ledger & Tax **nháp**, không phải Sales thật, OCR extraction,
thuế chính thức/chốt kỳ/tờ khai/báo cáo hoặc triển khai production. Snapshot service
chưa có API snapshot công khai mới; demo gọi service nội bộ. Freshness bảo thủ theo
household và chỉ đúng tại SELECT, không là bằng chứng Ledger bất biến.
Production migration/Household/Auth/Sales còn các đầu vào trong
[DUNG_INTEGRATION.md](DUNG_INTEGRATION.md). Các quyết định thuế thuộc BA/Ngọc Thái.
