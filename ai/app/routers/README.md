# Routers Module

Thư mục chứa các API Endpoint giao tiếp với hệ thống Backend và Mobile:
- `ocr.py`: Endpoint xử lý scan ảnh hóa đơn mua vào (`POST /api/v1/ocr/scan-invoice`)
- `chat.py`: Endpoint tiếp nhận câu hỏi và trả lời từ Trợ lý AI (`POST /api/v1/ai/chat`)