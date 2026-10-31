# TaxBook AI Service

Phân hệ AI hỗ trợ Trợ lý hỏi đáp Sổ sách/Thuế và OCR bóc tách Hóa đơn chi phí mua vào thuộc dự án DT13 (Hệ thống POS & Tự tính thuế cho Hộ kinh doanh).

## 1. Phạm vi & Nguyên tắc hệ thống
- **Trợ lý AI (RAG)**: Hỏi đáp về sổ sách và nghĩa vụ thuế. Mọi câu trả lời **bắt buộc kèm nguồn trích dẫn** số liệu/văn bản. Tự động từ chối trả lời khi thiếu dữ liệu đầu vào.
- **OCR Hóa đơn mua vào**: Trích xuất dữ liệu từ ảnh chụp hóa đơn ra **bản nháp chi phí**. Tuyệt đối không tự động ghi sổ khi người dùng chưa xác nhận.
- **Bảo mật & Quyền truy cập**: AI Service chỉ đọc dữ liệu qua các endpoint chỉ đọc (Read-only APIs), không truy cập trực tiếp vào cơ sở dữ liệu chính và không có quyền tự ghi sổ.

## 2. API Endpoints (Giao tiếp qua FastAPI)
- `POST /ai/ask`: Endpoint tiếp nhận câu hỏi sổ sách/thuế và trả về câu trả lời kèm nguồn dẫn.
- `POST /ai/expense-ocr`: Endpoint nhận ảnh hóa đơn và bóc tách thông tin nháp (Nhà cung cấp, ngày, tổng tiền, MST).

## 3. Cấu trúc thư mục module
- `app/routers/`: Khởi tạo các API endpoints (`/ai/ask`, `/ai/expense-ocr`).
- `app/schemas/`: Định nghĩa Pydantic Data Models chuẩn hóa dữ liệu Request/Response.
- `app/services/`: Logic xử lý lõi (Model OCR bóc tách ảnh & RAG truy vấn luật thuế).
- `tests/`: Kịch bản kiểm thử tự động (Unit Test & Integration Test).

## 4. Kế hoạch trọng tâm (Tuần 1–2)
- [ ] **Ngày 2–3**: Dựng khung dịch vụ FastAPI khớp API Contract, trả dữ liệu Mock (Sample JSON) chuẩn.
- [ ] **Tuần 1**: Kiểm thử OCR thử nghiệm trên 20–30 ảnh hóa đơn thực tế (đã che thông tin cá nhân) và đo độ chính xác bóc tách.
- [ ] **Tuần 1–2**: Xây dựng bộ 40–60 câu hỏi/đáp mẫu về sổ sách và thuế để đánh giá độ chính xác của RAG Chatbot.

---
*Ghi chú quản trị: Chỉ thành viên phụ trách phân hệ AI được sửa đổi trực tiếp. Các thay đổi khác cần mở Issue hoặc gửi Pull Request (PR) để review trước khi merge.*