import shutil
import os
import whisper 
from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI(title="BizFlow AI Service", version="1.0.0")

# --- Load Model Whisper (Chạy 1 lần khi khởi động app) ---
# Dùng model "base" cho nhẹ, nếu máy khỏe có thể đổi thành "small" hoặc "medium"
print("⏳ Đang tải model Whisper... (Sẽ mất vài giây)")
model = whisper.load_model("base")
print("✅ Đã tải xong model!")

# --- Output Model ---
class OrderItem(BaseModel):
    sku: str
    qty: int
    unit: str

class DraftOrderResponse(BaseModel):
    customer_name: str
    items: List[OrderItem]
    raw_text: str

@app.get("/")
def read_root():
    return {"message": "AI Service is running with Whisper Model!"}

@app.post("/api/ai/analyze-audio", response_model=DraftOrderResponse)
async def analyze_audio(file: UploadFile = File(...)):
    temp_filename = "temp_audio.mp3"
    
    try:
        # 1. Lưu file upload tạm thời xuống ổ đĩa
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 2. Dùng Whisper để dịch (Transcribe)
        result = model.transcribe(temp_filename)
        text_result = result["text"]
        
        # 3. TODO: Tuần sau sẽ làm đoạn tách từ khóa (NLP/RAG) ở đây
        # Hiện tại mình hardcode phần Items, nhưng trả về raw_text THẬT từ giọng nói
        
        return {
            "customer_name": "Khách Vãng Lai", 
            "items": [
                {"sku": "DEMO_PRODUCT", "qty": 1, "unit": "cai"}
            ],
            "raw_text": text_result # <--- Kết quả AI nghe được sẽ hiện ở đây
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # Dọn dẹp file tạm
        if os.path.exists(temp_filename):
            os.remove(temp_filename)