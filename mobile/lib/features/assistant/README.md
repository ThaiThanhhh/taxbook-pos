# Trợ lý AI

Phân hệ chat dùng `AssistantRepository` để gọi `POST /ai/ask`, lưu hội thoại
trong `assistantChatProvider` và hiển thị câu trả lời cùng nguồn trích dẫn.
Khi endpoint chưa sẵn sàng hoặc không kết nối được, repository dùng các quy
tắc HKDN 2026 có sẵn và đánh dấu câu trả lời bằng `isFallback`.

Màn hình được đăng ký tại route `/assistant`. Repository và giao diện được
kiểm thử trong `test/features/assistant/`.
