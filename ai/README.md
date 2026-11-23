# TaxBook POS - AI Service Module (Dự án DT13)

Phân hệ AI hỗ trợ Trợ lý hỏi đáp Sổ sách/Thuế (RAG Chatbot) và OCR bóc tách Hóa đơn chi phí mua vào thuộc hệ thống TaxBook POS (Tự tính thuế cho Hộ kinh doanh).

---

## 1. Phạm vi & Nguyên tắc hệ thống
- **Trợ lý AI (RAG)**: Hỏi đáp về sổ sách và nghĩa vụ thuế. Mọi câu trả lời **bắt buộc kèm nguồn trích dẫn** số liệu/văn bản. Tự động từ chối trả lời khi thiếu dữ liệu đầu vào.
- **OCR Hóa đơn mua vào**: Trích xuất dữ liệu từ ảnh chụp hóa đơn ra **bản nháp chi phí** (Nhà cung cấp, Ngày, Tổng tiền, MST). Tuyệt đối không tự động ghi sổ khi người dùng chưa xác nhận (`need_user_confirmation: true`).
- **Bảo mật & Quyền truy cập**: AI Service chỉ đọc dữ liệu qua các endpoint chỉ đọc (Read-only APIs), không truy cập trực tiếp vào cơ sở dữ liệu chính và không có quyền tự ghi sổ.

---

## 2. 🏗 Kiến trúc dự án (Enterprise 3-Layer Architecture)

Dự án được thiết kế chuẩn phân tầng doanh nghiệp:

```text
ai/
├── app/
│   ├── main.py              # Entry Point chính của FastAPI
│   ├── routers/             # Tầng Router (Tiếp nhận & Định tuyến RESTful APIs)
│   │   └── ocr_router.py    # Endpoint /api/v1/ocr/upload & status
│   ├── schemas/             # Tầng Schema (Pydantic Models Data Validation)
│   │   └── ocr_schema.py    # Cấu trúc Response/Request JSON
│   └── services/            # Tầng Service (Xử lý nghiệp vụ lõi OCR & RAG)
│       └── ocr_service.py   # OCR Extraction Logic & Mock Data Engine
├── tests/                   # Bộ Kiểm thử tự động (Unit Tests)
│   ├── __init__.py
│   └── test_ocr.py          # Pytest validation test cases
├── requirements.txt         # Thư viện phụ thuộc
└── README.md