from fastapi.testclient import TestClient
from app.main import app

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
    assert "Dinh dang file khong hop le" in response.json()["detail"]

def test_upload_valid_image():
    """Test upload file anh hop le phai tra ve extracted_data"""
    files = {"file": ("test_invoice.jpg", b"fake_image_bytes", "image/jpeg")}
    response = client.post("/api/v1/ocr/upload", files=files)
    assert response.status_code == 200
    data = response.json()
    assert data["filename"] == "test_invoice.jpg"
    assert "extracted_data" in data
    assert data["extracted_data"]["seller_vat_code"] == "0312345678"