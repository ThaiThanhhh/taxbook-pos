from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.ocr_service import ocr_service
from app.schemas.ocr_schema import OCRUploadResponse

router = APIRouter(prefix="/api/v1/ocr", tags=["OCR Service"])
MAX_FILE_SIZE = 5 * 1024 * 1024

@router.get("/status")
def get_ocr_status():
    """Endpoint kiem tra trang thai module OCR"""
    return {
        "module": "OCR Engine",
        "engine": "Tesseract/EasyOCR",
        "ready": True
    }

@router.post("/upload", response_model=OCRUploadResponse)
async def upload_invoice(file: UploadFile = File(...)):
    """Endpoint nhan file anh, tien xu ly va boc tach du lieu hoa don"""
    allowed_extensions = ["image/jpeg", "image/png", "image/jpg"]
    if file.content_type not in allowed_extensions:
        raise HTTPException(
            status_code=400, 
            detail="Dinh dang file khong hop le (chi chap nhan JPG, PNG)"
        )

    contents = await file.read()
    file_size = len(contents)
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"Dung luong file vuot qua gioi han cho phep (Toi da {MAX_FILE_SIZE // (1024*1024)}MB)"
        )

    ocr_service.preprocess_image(contents)
    raw_text = await ocr_service.extract_raw_text(contents)
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