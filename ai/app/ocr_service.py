# ai/app/ocr_service.py

class OCRService:
    def __init__(self):
        # Khởi tạo engine OCR (sau này sẽ load model Tesseract/EasyOCR)
        self.engine_name = "EasyOCR/Tesseract"

    async def extract_raw_text(self, file_bytes: bytes) -> str:
        """Hàm mô phỏng đọc file ảnh và trả về văn bản thô (raw text)"""
        if not file_bytes:
            return ""
        
        # Mockup dữ liệu text đọc ra từ hóa đơn để kiểm thử API
        mock_extracted_text = (
            "CÔNG TY TNHH TAXBOOK POS\n"
            "Mã số thuế: 0312345678\n"
            "Ngày xuất: 03/11/2026\n"
            "Mặt hàng: Phần mềm quản lý bán hàng\n"
            "Tổng tiền thanh toán: 1,500,000 VND\n"
            "Tiền thuế GTGT (10%): 150,000 VND"
        )
        return mock_extracted_text

# Khởi tạo instance dùng chung
ocr_service = OCRService()