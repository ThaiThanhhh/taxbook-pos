from fastapi import FastAPI

app = FastAPI(
    title="TaxBook POS - AI Service",
    description="Module dich vu AI ho tro giai dap thue va OCR hoa don"
)

@app.get("/")
def read_root():
    return {
        "service": "TaxBook AI Service",
        "status": "active"
    }

@app.get("/healthcheck")
def health_check():
    return {"status": "ok"}

@app.get("/api/v1/ocr/status")
def get_ocr_status():
    """Endpoint kiem tra trang thai module OCR"""
    return {
        "module": "OCR Engine",
        "engine": "Tesseract/EasyOCR",
        "ready": True
    }