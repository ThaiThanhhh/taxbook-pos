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
