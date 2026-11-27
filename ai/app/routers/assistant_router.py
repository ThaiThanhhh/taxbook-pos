from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.services.assistant_service import LedgerAssistantService

router = APIRouter(prefix="/assistant", tags=["AI Ledger Assistant"])


class AskRequest(BaseModel):
    question: str = Field(..., min_length=2, json_schema_extra={"example": "Tháng này tôi nộp bao nhiêu thuế?"})
    household_id: str = Field(default="HKD_COMTAM_01", json_schema_extra={"example": "HKD_COMTAM_01"})


@router.post("/ask", summary="Hỏi đáp sổ sách & thuế dẫn nguồn số liệu")
async def ask_ledger_assistant(payload: AskRequest):
    if not payload.question.strip():
        raise HTTPException(status_code=400, detail="Vui lòng nhập nội dung câu hỏi.")
    return LedgerAssistantService.answer_question(
        question=payload.question,
        household_id=payload.household_id
    )