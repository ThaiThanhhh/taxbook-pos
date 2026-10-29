# ai – trợ lý hỏi đáp và OCR chi phí

**Chủ:** Văn Thành

## Phạm vi
- Hỏi đáp về sổ và thuế, mọi câu trả lời kèm nguồn, từ chối khi thiếu dữ liệu
- OCR ảnh hóa đơn mua vào ra bản nháp chi phí (chưa vào sổ khi chưa xác nhận)
- AI chỉ đọc qua endpoint chỉ đọc, không truy cập cơ sở dữ liệu trực tiếp, không tự ghi sổ

## API liên quan (xem `api/openapi.yaml`)
- `/ai/ask`, `/ai/expense-ocr`

## Việc làm ngay (tuần 1–2)
- [ ] Ngày 2–3: khung dịch vụ khớp hợp đồng, trả dữ liệu mẫu
- [ ] Tuần 1: thử OCR trên 20–30 ảnh (che thông tin cá nhân), đo độ chính xác
- [ ] Tuần 1–2: bộ 40–60 câu hỏi đánh giá cùng Ngọc Thái

Chỉ chủ thư mục được sửa trực tiếp. Người khác cần thay đổi thì mở issue hoặc PR để chủ duyệt.
