from fastapi import FastAPI, UploadFile, File, HTTPException
from app.ocr_service import ocr_service

app = FastAPI(
    title="TaxBook POS - AI Service",
    description="Module dich vu AI ho tro giai dap thue va OCR hoa don"
)
MAX_FILE_SIZE = 5 * 1024 * 1024

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

    # 2. Kiem tra dung luong file
    contents = await file.read()
    file_size = len(contents)
    
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"Dung luong file vuot qua gioi han cho phep (Toi da {MAX_FILE_SIZE // (1024*1024)}MB)"
        )
    
  # 3. Tien xu ly anh va doc raw text tu OCR Service
    ocr_service.preprocess_image(contents)
    raw_text = await ocr_service.extract_raw_text(contents)
    # 4. Boc tach du lieu co cau truc qua Regex
    extracted_data = ocr_service.extract_structured_data(raw_text)

    return {
        "filename": file.filename,
        "content_type": file.content_type,
        "file_size_bytes": file_size,
        "raw_text": raw_text,
        "extracted_data": extracted_data,
        "need_user_confirmation": True,
        "message": "Upload file anh hoa don thanh cong, san sang cho xu ly OCR"
    }
