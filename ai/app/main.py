from fastapi import FastAPI
from app.routers import ocr_router

app = FastAPI(
    title="TaxBook POS - AI Service",
    description="Module dich vu AI ho tro giai dap thue va OCR hoa don"
)

# Include router tu thu muc routers
app.include_router(ocr_router.router)

@app.get("/")
def read_root():
    return {"service": "TaxBook AI Service", "status": "active"}

@app.get("/healthcheck")
def health_check():
    return {"status": "ok"}