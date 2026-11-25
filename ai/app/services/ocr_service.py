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

        # Địa chỉ nhà cung cấp
        address_pattern = r'(?:địa\s*chỉ|đ/c|address)[\s.:]*([^\n]+)'
        address_match = re.search(address_pattern, text, re.IGNORECASE)
        vendor_address = address_match.group(1).strip() if address_match else None

        # Số điện thoại liên hệ (VD: 028 3812 3456, 0901234567, +84...)
        phone_pattern = r'(?:điện\s*thoại|sđt|tel|phone|hotline)[\s.:]*([0-9+().\s-]{9,18})'
        phone_match = re.search(phone_pattern, text, re.IGNORECASE)
        vendor_phone = re.sub(r'[^\d+]', '', phone_match.group(1)) if phone_match else None

        # Tên đơn vị mua hàng (Khách hàng)
        buyer_pattern = r'(?:đơn\s*vị\s*mua\s*hàng|tên\s*đơn\s*vị\s*mua|khách\s*hàng|buyer)[\s.:]*([^\n]+)'
        buyer_match = re.search(buyer_pattern, text, re.IGNORECASE)
        buyer_name = buyer_match.group(1).strip() if buyer_match else None

        # Mã số thuế đơn vị mua hàng (MST thứ 2 trên hóa đơn hoặc đứng sau nhãn người mua)
        all_mst = re.findall(r'\b\d{10}(?:-\d{3})?\b', text)
        buyer_tax_code = all_mst[1] if len(all_mst) >= 2 else None

        # Ký hiệu hóa đơn điện tử (VD: 1C26TAA, 2C26TYY, AA/26E)
        serial_pattern = r'(?:ký\s*hiệu|serial|kí\s*hiệu)[\s.:]*([A-Z0-9/-]{5,10})\b'
        serial_match = re.search(serial_pattern, text, re.IGNORECASE)
        invoice_serial = serial_match.group(1).upper() if serial_match else None

        # Số hóa đơn (VD: Số: 0001234 hoặc Invoice No: 123456)
        inv_num_pattern = r'(?:số\s*hóa\s*đơn|số|invoice\s*no|no)[\s.:]*(\d{5,8})\b'
        inv_num_match = re.search(inv_num_pattern, text, re.IGNORECASE)
        invoice_number = inv_num_match.group(1) if inv_num_match else None  

        # Mã tra cứu hóa đơn điện tử (VD: Mã tra cứu: ABC123XYZ89)
        lookup_code_pattern = r'(?:mã\s*tra\s*cứu|mã\s*nhận\s*hóa\s*đơn|lookup\s*code)[\s.:]*([A-Z0-9]{8,20})\b'
        lookup_code_match = re.search(lookup_code_pattern, text, re.IGNORECASE)
        lookup_code = lookup_code_match.group(1).upper() if lookup_code_match else None

        # Đường dẫn tra cứu hóa đơn (URL)
        url_pattern = r'(https?://[^\s<>"]+|www\.[^\s<>"]+)'
        url_match = re.search(url_pattern, text, re.IGNORECASE)
        lookup_url = url_match.group(0).rstrip('.,;)') if url_match else None

        # Mã của Cơ quan thuế (Chuỗi 34 ký tự chữ hoa và số chuẩn Thông tư 78)
        cqt_pattern = r'(?:mã\s*(?:của\s*)?cơ\s*quan\s*thuế|mã\s*cqt)[\s.:]*([A-Z0-9]{30,36})\b'
        cqt_match = re.search(cqt_pattern, text, re.IGNORECASE)
        tax_authority_code = cqt_match.group(1).upper() if cqt_match else None

        # Hình thức thanh toán (VD: TM/CK, Tiền mặt, Chuyển khoản)
        payment_pattern = r'(?:hình\s*thức\s*thanh\s*toán|httt|payment\s*method)[\s.:]*([^\n]+)'
        payment_match = re.search(payment_pattern, text, re.IGNORECASE)
        payment_method = payment_match.group(1).strip() if payment_match else None

        # Số tài khoản ngân hàng (8 - 16 chữ số)
        bank_acc_pattern = r'(?:số\s*tài\s*khoản|stk|account\s*no)[\s.:]*(\d{8,16})\b'
        bank_acc_match = re.search(bank_acc_pattern, text, re.IGNORECASE)
        bank_account = bank_acc_match.group(1) if bank_acc_match else None

        # Tên ngân hàng thụ hưởng (VD: Ngân hàng TMCP Kỹ Thương Việt Nam - Techcombank)
        bank_name_pattern = r'(?:ngân\s*hàng|bank|tại\s*nh)[\s.:]*([^\n]+)'
        bank_name_match = re.search(bank_name_pattern, text, re.IGNORECASE)
        bank_name = bank_name_match.group(1).strip() if bank_name_match else None

        # 1. Mã số thuế (MST): 10 hoặc 13 chữ số
        mst_pattern = r'\b\d{10}(?:-\d{3})?\b'
        mst_match = re.search(mst_pattern, text)
        mst = mst_match.group(0) if mst_match else None

        # 2. Ngày hóa đơn (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)
        date_pattern = r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b'
        date_match = re.search(date_pattern, text)
        date = date_match.group(0) if date_match else None

        # Chuẩn hóa ngày hóa đơn sang định dạng ISO (YYYY-MM-DD) cho PostgreSQL
        invoice_date_iso = None
        if date:
            parts = re.split(r'[/-]', date)
            if len(parts[0]) == 4:
                invoice_date_iso = f"{parts[0]}-{parts[1].zfill(2)}-{parts[2].zfill(2)}"
            else:
                invoice_date_iso = f"{parts[2]}-{parts[1].zfill(2)}-{parts[0].zfill(2)}"
                
        # 2. Ngày hóa đơn (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)
        date_pattern = r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b'
        date_match = re.search(date_pattern, text)
        date = date_match.group(0) if date_match else None

        # Tiền hàng trước thuế (Cộng tiền hàng / Subtotal)
        subtotal_pattern = r'(?:cộng\s*tiền\s*hàng|tiền\s*trước\s*thuế|subtotal)[\s:]*([0-9.,]+)'
        subtotal_match = re.search(subtotal_pattern, text, re.IGNORECASE)
        subtotal_amount = None
        if subtotal_match:
            clean_sub = re.sub(r'[^\d]', '', subtotal_match.group(1))
            if clean_sub:
                subtotal_amount = float(clean_sub)

        # Thuế suất VAT (VD: 8%, 10%, 0%)
        vat_rate_pattern = r'(?:thuế\s*suất(?:\s*gtgt)?|vat)[\s:]*(\d{1,2})\s*%'
        vat_rate_match = re.search(vat_rate_pattern, text, re.IGNORECASE)
        vat_rate = int(vat_rate_match.group(1)) if vat_rate_match else None

        # Tiền thuế GTGT / VAT
        vat_amt_pattern = r'(?:tiền\s*thuế\s*gtgt|tiền\s*thuế|vat\s*amount)[\s:]*([0-9.,]+)'
        vat_amt_match = re.search(vat_amt_pattern, text, re.IGNORECASE)
        vat_amount = None
        if vat_amt_match:
            clean_vat = re.sub(r'[^\d]', '', vat_amt_match.group(1))
            if clean_vat:
                vat_amount = float(clean_vat)

        # 3. Tổng tiền thanh toán
        amount_pattern = r'(?:tổng\s+cộng\s+tiền\s+thanh\s+toán|tổng\s+tiền\s+thanh\s+toán|tổng\s+cộng|tổng\s+tiền|total\s+amount|thành\s+tiền)[\s:]*([0-9.,]+)'
        amount_match = re.search(amount_pattern, text, re.IGNORECASE)
        total_amount = None
        if amount_match:
            clean_digits = re.sub(r'[^\d]', '', amount_match.group(1))
            if clean_digits:
                total_amount = float(clean_digits)

        # Đơn vị tiền tệ (Mặc định VND nếu không ghi USD/EUR)
        currency_pattern = r'\b(VND|VNĐ|USD|EUR)\b'
        currency_match = re.search(currency_pattern, text, re.IGNORECASE)
        currency = "VND"
        if currency_match:
            raw_curr = currency_match.group(1).upper()
            currency = "VND" if raw_curr in ("VND", "VNĐ") else raw_curr

        # Số tiền viết bằng chữ (VD: Số tiền viết bằng chữ: Hai triệu năm trăm nghìn đồng chẵn)
        words_pattern = r'(?:số\s*tiền\s*(?:viết\s*)?bằng\s*chữ|bằng\s*chữ|in\s*words)[\s.:]*([^\n]+)'
        words_match = re.search(words_pattern, text, re.IGNORECASE)
        amount_in_words = words_match.group(1).strip() if words_match else None

        # Tự động tính bù giá trị nếu thiếu tổng tiền hoặc tiền thuế
        if subtotal_amount is not None and vat_rate is not None:
            if vat_amount is None:
                vat_amount = round(subtotal_amount * (vat_rate / 100), 2)
            if total_amount is None:
                total_amount = round(subtotal_amount + vat_amount, 2)

        # Đối soát chéo số học VAT (Sai số cho phép <= 10 VNĐ do làm tròn)
        is_vat_valid = True
        if vat_amount is not None and total_amount is not None and vat_rate is not None:
            expected_subtotal = total_amount / (1 + vat_rate / 100)
            expected_vat = total_amount - expected_subtotal
            if abs(expected_vat - vat_amount) > 10:
                is_vat_valid = False

        # 4. Đánh giá độ tin cậy
        need_confirmation = True if (not mst or not total_amount or not date or not is_vat_valid) else False
        return {
            "vendor_name": vendor_name,
            "vendor_address": vendor_address,
            "vendor_phone": vendor_phone,
            "buyer_name": buyer_name,
            "buyer_tax_code": buyer_tax_code,
            "tax_code": mst,
            "invoice_number": invoice_number,
            "lookup_code": lookup_code,
            "lookup_url": lookup_url,
            "tax_authority_code": tax_authority_code,
            "payment_method": payment_method,
            "bank_account": bank_account,
            "bank_name": bank_name,
            "invoice_serial": invoice_serial,
            "invoice_date": date,
            "invoice_date_iso": invoice_date_iso,
            "subtotal_amount": subtotal_amount,
            "vat_rate": vat_rate,
            "vat_amount": vat_amount,
            "is_vat_valid": is_vat_valid,
            "total_amount": total_amount,
            "currency": currency,
            "amount_in_words": amount_in_words,
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