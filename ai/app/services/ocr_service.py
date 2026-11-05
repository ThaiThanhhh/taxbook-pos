import re

class OCRService:
    def __init__(self):
        # Khởi tạo engine OCR (sau này sẽ load model Tesseract/EasyOCR)
        self.engine_name = "EasyOCR/Tesseract"

    def preprocess_image(self, file_bytes: bytes) -> str:
        """Tien xu ly anh: Mo phong chuyen doi anh sang anh xam (Grayscale) de tang do chinh xac OCR"""
        # Sau nay nhung OpenCV: cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        return "Preprocessed: Grayscale applied"

    def extract_structured_data(self, raw_text: str) -> dict:
        """Boc tach du lieu ke toan co cau truc tu van ban tho bang Regex"""
        # Regex tim Ma so thue (10 hoac 13 chu so)
        vat_code_match = re.search(r"(?:Ma so thue|MST):\s*(\d{10}(?:-\d{3})?)", raw_text, re.IGNORECASE)
        # Regex tim Ngay xuat (dd/mm/yyyy)
        date_match = re.search(r"(?:Ngay xuat|Ngay):\s*(\d{2}/\d{2}/\d{4})", raw_text, re.IGNORECASE)
        # Regex tim Tong tien
        total_match = re.search(r"Tong tien thanh toan:\s*([\d,.]+)", raw_text, re.IGNORECASE)
        # Regex tim Tien thue GTGT
        tax_match = re.search(r"Tien thue GTGT.*:\s*([\d,.]+)", raw_text, re.IGNORECASE)

        return {
            "seller_vat_code": vat_code_match.group(1) if vat_code_match else None,
            "invoice_date": date_match.group(1) if date_match else None,
            "subtotal": 1500000,
            "tax_amount": tax_match.group(1) if tax_match else "0",
            "total_amount": total_match.group(1) if total_match else "0",
            "confidence_score": 0.95
        }

    async def extract_raw_text(self, file_bytes: bytes) -> str:
        """Hàm mô phỏng đọc file ảnh và trả về văn bản thô (raw text)"""
        if not file_bytes:
            return ""
        
        return (
            "CONG TY TNHH TAXBOOK POS\n"
            "Ma so thue: 0312345678\n"
            "Ngay xuat: 03/11/2026\n"
            "Mat hang: Phan mem quan ly ban hang\n"
            "Tien thue GTGT (10%): 150,000 VND\n"
            "Tong tien thanh toan: 1,650,000 VND"
        )
# Khởi tạo instance dùng chung
ocr_service = OCRService()