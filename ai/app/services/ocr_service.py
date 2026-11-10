import re
import cv2
import numpy as np
import pytesseract
from PIL import Image
import io
from typing import Dict, Any

class OCRService:
    @staticmethod
    def preprocess_image(image_bytes: bytes) -> np.ndarray:
        """
        Tiền xử lý ảnh hóa đơn nâng cao với OpenCV:
        1. Chuyển Grayscale
        2. Khử nhiễu Fast NlMeans Denoising
        3. Otsu Thresholding bóc tách chữ
        """
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise ValueError("Không thể đọc định dạng ảnh đầu vào")

        # 1. Grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # 2. Khử nhiễu nhẹ
        denoised = cv2.fastNlMeansDenoising(gray, h=10)

        # 3. Phân ngưỡng Otsu nhị phân
        _, thresh = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        return thresh

    @staticmethod
    def extract_raw_text(processed_img: np.ndarray) -> str:
        """
        Trích xuất văn bản thô từ ảnh đã qua xử lý bằng Tesseract OCR (Hỗ trợ tiếng Việt & Anh)
        """
        custom_config = r'--oem 3 --psm 6'
        raw_text = pytesseract.image_to_string(processed_img, lang='vie+eng', config=custom_config)
        return raw_text.strip()

    @staticmethod
    def parse_invoice_data(text: str) -> Dict[str, Any]:
        """
        Bóc tách chi tiết các trường dữ liệu kế toán bằng Regex Việt Nam
        """
        # 1. Mã số thuế (MST): 10 hoặc 13 chữ số (VD: 0312345678 hoặc 0312345678-001)
        mst_pattern = r'\b\d{10}(?:-\d{3})?\b'
        mst_match = re.search(mst_pattern, text)
        mst = mst_match.group(0) if mst_match else None

        # 2. Ngày hóa đơn (Định dạng: DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)
        date_pattern = r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b'
        date_match = re.search(date_pattern, text)
        date = date_match.group(0) if date_match else None

        # 3. Tổng tiền thanh toán (Bắt cụm từ khóa và bóc sạch chuỗi số)
        amount_pattern = r'(?:tổng\s+cộng\s+tiền\s+thanh\s+toán|tổng\s+tiền\s+thanh\s+toán|tổng\s+cộng|tổng\s+tiền|total\s+amount|thành\s+tiền)[\s:]*([0-9.,]+)'
        amount_match = re.search(amount_pattern, text, re.IGNORECASE)
        total_amount = None
        if amount_match:
            # Loại bỏ tất cả ký tự không phải là chữ số (\d)
            clean_digits = re.sub(r'[^\d]', '', amount_match.group(1))
            if clean_digits:
                total_amount = float(clean_digits)

        # 4. Đánh giá độ tin cậy (Need Confirmation)
        need_confirmation = True if (not mst or not total_amount or not date) else False

        return {
            "tax_code": mst,
            "invoice_date": date,
            "total_amount": total_amount,
            "raw_text": text,
            "need_user_confirmation": need_confirmation
        }

    @classmethod
    def process_invoice(cls, image_bytes: bytes) -> Dict[str, Any]:
        """
        Pipeline xử lý hoàn chỉnh
        """
        processed_img = cls.preprocess_image(image_bytes)
        raw_text = cls.extract_raw_text(processed_img)
        parsed_data = cls.parse_invoice_data(raw_text)
        return parsed_data