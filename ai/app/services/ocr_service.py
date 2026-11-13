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
        1. Decode & Upscale ảnh nhỏ để tăng DPI cho Tesseract
        2. Chuyển Grayscale
        3. Khử nhiễu Fast NlMeans Denoising
        4. Otsu Thresholding bóc tách chữ
        """
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise ValueError("Không thể đọc định dạng ảnh đầu vào")

        # 1. Upscale nếu chiều rộng ảnh nhỏ hơn 1000px để tăng độ nét ký tự
        height, width = img.shape[:2]
        if width < 1000:
            scale_factor = 1000 / width
            img = cv2.resize(img, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_CUBIC)

        # 2. Grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # 3. Khử nhiễu nhẹ
        denoised = cv2.fastNlMeansDenoising(gray, h=10)

        # 4. Phân ngưỡng Otsu nhị phân
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
        # Tên đơn vị bán hàng / Nhà cung cấp
        vendor_pattern = r'(?:CÔNG\s+TY|DOANH\s+NGHIỆP|HỘ\s+KINH\s+DOANH|CHI\s+NHÁNH)[^\n]+'
        vendor_match = re.search(vendor_pattern, text, re.IGNORECASE)
        vendor_name = vendor_match.group(0).strip() if vendor_match else None

        # Số hóa đơn (VD: Số: 0001234 hoặc Invoice No: 123456)
        inv_num_pattern = r'(?:số\s*hóa\s*đơn|số|invoice\s*no|no)[\s.:]*(\d{5,8})\b'
        inv_num_match = re.search(inv_num_pattern, text, re.IGNORECASE)
        invoice_number = inv_num_match.group(1) if inv_num_match else None
        
        # 1. Mã số thuế (MST): 10 hoặc 13 chữ số
        mst_pattern = r'\b\d{10}(?:-\d{3})?\b'
        mst_match = re.search(mst_pattern, text)
        mst = mst_match.group(0) if mst_match else None

        # 2. Ngày hóa đơn (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)
        date_pattern = r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b'
        date_match = re.search(date_pattern, text)
        date = date_match.group(0) if date_match else None

        # 3. Tổng tiền thanh toán
        amount_pattern = r'(?:tổng\s+cộng\s+tiền\s+thanh\s+toán|tổng\s+tiền\s+thanh\s+toán|tổng\s+cộng|tổng\s+tiền|total\s+amount|thành\s+tiền)[\s:]*([0-9.,]+)'
        amount_match = re.search(amount_pattern, text, re.IGNORECASE)
        total_amount = None
        if amount_match:
            clean_digits = re.sub(r'[^\d]', '', amount_match.group(1))
            if clean_digits:
                total_amount = float(clean_digits)

        # 4. Đánh giá độ tin cậy
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