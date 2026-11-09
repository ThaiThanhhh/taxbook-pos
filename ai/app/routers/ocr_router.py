from fastapi import APIRouter, UploadFile, File, HTTPException, status
from app.services.ocr_service import OCRService
from typing import Dict, Any

router = APIRouter(
    prefix="/api/v1/ocr",
    tags=["OCR Service"]
)

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_EXTENSIONS = {"image/jpeg", "image/png", "image/webp", "image/jpg"}

@router.get("/status")
def get_ocr_status():
    """Endpoint kiem tra trang thai module OCR"""
    return {
        "module": "OCR Engine",
        "engine": "Tesseract/OpenCV",
        "ready": True
    }

@router.post("/upload", response_model=Dict[str, Any], status_code=status.HTTP_200_OK)
async def upload_invoice(file: UploadFile = File(...)):
    """
    Endpoint nhận file ảnh hóa đơn, xử lý OCR và trích xuất dữ liệu kế toán:
    - Mã số thuế (tax_code)
    - Ngày hóa đơn (invoice_date)
    - Tổng tiền (total_amount)
    """
    # 1. Kiểm tra định dạng file
    if file.content_type not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Định dạng file không hợp lệ. Chỉ chấp nhận JPG, PNG, WEBP."
        )

    # 2. Đọc binary dữ liệu ảnh
    contents = await file.read()
    file_size = len(contents)

    # 3. Kiểm tra dung lượng file (Tối đa 5MB)
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Dung lượng file vượt quá giới hạn cho phép (Tối đa {MAX_FILE_SIZE // (1024*1024)}MB)"
        )

    try:
        # 4. Gọi Pipeline OCR Service hoàn chỉnh
        extracted_data = OCRService.process_invoice(contents)

        # 5. Trả về kết quả JSON chuẩn hóa
        return {
            "filename": file.filename,
            "content_type": file.content_type,
            "file_size_bytes": file_size,
            "status": "success",
            "extracted_data": extracted_data,
            "message": "Xử lý OCR và bóc tách dữ liệu hóa đơn thành công"
        }

    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(ve)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi hệ thống khi xử lý OCR: {str(e)}"
        )