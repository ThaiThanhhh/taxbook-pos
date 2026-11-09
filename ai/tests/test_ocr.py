import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from app.main import app
from app.services.ocr_service import OCRService

client = TestClient(app)

def test_read_root():
    """Test endpoint trang chu"""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"service": "TaxBook AI Service", "status": "active"}

def test_health_check():
    """Test endpoint healthcheck"""
    response = client.get("/healthcheck")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_upload_invalid_file_type():
    """Test upload file sai dinh dang (file txt) phai tra ve loi 400"""
    files = {"file": ("test.txt", b"dummy content", "text/plain")}
    response = client.post("/api/v1/ocr/upload", files=files)
    assert response.status_code == 400
    assert "Định dạng file không hợp lệ" in response.json()["detail"]

@patch.object(OCRService, "process_invoice")
def test_upload_valid_image_endpoint(mock_process):
    """Test upload file ảnh hợp lệ kết nối thành công tới OCR Engine"""
    mock_process.return_value = {
        "tax_code": "0312345678",
        "invoice_date": "11/11/2026",
        "total_amount": 2500000.0,
        "raw_text": "HÓA ĐƠN...",
        "need_user_confirmation": False
    }
    
    files = {"file": ("invoice.jpg", b"fake_image_bytes", "image/jpeg")}
    response = client.post("/api/v1/ocr/upload", files=files)
    
    assert response.status_code == 200
    data = response.json()
    assert data["filename"] == "invoice.jpg"
    assert data["status"] == "success"
    assert data["extracted_data"]["tax_code"] == "0312345678"
    assert data["extracted_data"]["total_amount"] == 2500000.0

def test_parse_invoice_data_success():
    """Unit test kiem tra bóc tách Regex thành công đủ thông tin"""
    mock_text = """
    HÓA ĐƠN GIÁ TRỊ GIA TĂNG
    CÔNG TY CỔ PHẦN ZENTECH
    Mã số thuế: 0312345678
    Ngày xuất: 11/11/2026
    Tổng cộng tiền thanh toán: 2.500.000 VNĐ
    """
    result = OCRService.parse_invoice_data(mock_text)
    assert result["tax_code"] == "0312345678"
    assert result["invoice_date"] == "11/11/2026"
    assert result["total_amount"] == 2500000.0
    assert result["need_user_confirmation"] is False

def test_parse_invoice_data_with_branch_tax_code():
    """Unit test kiem tra bóc tách Mã số thuế chi nhánh (13 số)"""
    mock_text = """
    CÔNG TY TNHH SOFTWARE ZEN
    MST: 0109876543-123
    Ngày xuất: 07/11/2026
    Tổng tiền thanh toán: 2.200.000
    """
    result = OCRService.parse_invoice_data(mock_text)
    assert result["tax_code"] == "0109876543-123"
    assert result["invoice_date"] == "07/11/2026"
    assert result["total_amount"] == 2200000.0
    assert result["need_user_confirmation"] is False

def test_parse_invoice_data_missing_fields():
    """Unit test kiem tra trường hợp thiếu thông tin hóa đơn"""
    mock_text = "Hóa đơn không rõ nội dung"
    result = OCRService.parse_invoice_data(mock_text)
    assert result["tax_code"] is None
    assert result["total_amount"] is None
    assert result["need_user_confirmation"] is True