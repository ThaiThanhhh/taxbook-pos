from pydantic import BaseModel
from typing import Optional

class ExtractedDataResponse(BaseModel):
    seller_vat_code: Optional[str] = None
    invoice_date: Optional[str] = None
    subtotal: float
    tax_amount: str
    total_amount: str
    confidence_score: float

class OCRUploadResponse(BaseModel):
    filename: str
    content_type: str
    file_size_bytes: int
    raw_text: str
    extracted_data: ExtractedDataResponse
    need_user_confirmation: bool
    message: str