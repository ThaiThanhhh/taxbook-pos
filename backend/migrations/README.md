Migration cơ sở dữ liệu do backend quản lý.

Runner PostgreSQL rehearsal test, tracking/checksum, transaction/rollback và upgrade
schema cũ: xem [DEMO_HANDOFF.md](../DEMO_HANDOFF.md). Chạy `npm run test:migrations`
với `TEST_DATABASE_URL`. Runner chỉ dùng schema test riêng, chưa cấp số migration
production và không tự áp dụng vào DB nhóm.
