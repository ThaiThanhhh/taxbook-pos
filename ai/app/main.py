from fastapi import FastAPI, UploadFile, File, HTTPException

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

@app.post("/api/v1/ocr/upload")
async def upload_invoice(file: UploadFile = File(...)):
    allowed_extensions = ["image/jpeg", "image/png", "image/jpg"]
    
    if file.content_type not in allowed_extensions:
        raise HTTPException(
            status_code=400, 
            detail="Dinh dang file khong hop le (chi chap nhan JPG, PNG)"
        )
    
    return {
        "filename": file.filename,
        "content_type": file.content_type,
        "message": "Upload file anh hoa don thanh cong, san sang cho xu ly OCR"
    }