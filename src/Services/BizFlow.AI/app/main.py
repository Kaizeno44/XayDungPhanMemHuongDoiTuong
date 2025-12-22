from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Any
import os
import google.generativeai as genai

# Import 2 service vừa viết
from app.services.stt_service import transcribe_audio
from app.services.nlp_service import extract_order_info
from app.services.rag_service import rag_client # Vẫn giữ kết nối ChromaDB

app = FastAPI(title="BizFlow AI Service", version="1.0.0")

# --- MODEL RESPONSE ---
class DraftOrderResponse(BaseModel):
    success: bool
    message: str
    data: Any # Cho phép linh động JSON trả về

@app.on_event("startup")
async def startup_event():
    try:
        api_key = os.getenv("GEMINI_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
            print("======= DANH SÁCH MODEL GEMINI KHẢ DỤNG =======")
            for m in genai.list_models():
                if 'generateContent' in m.supported_generation_methods:
                    print(f"- {m.name}")
            print("===============================================")
    except Exception as e:
        print(f"Lỗi check model: {e}")

@app.get("/")
def health_check():
    chroma_status = rag_client.check_health()
    return {"service": "AI Service Real", "chroma": chroma_status}

@app.post("/api/ai/analyze-voice", response_model=DraftOrderResponse)
async def analyze_voice(file: UploadFile = File(...)):
    # 1. Validation file
    if not file.filename.lower().endswith(('.wav', '.mp3', '.m4a', '.ogg')):
        return DraftOrderResponse(success=False, message="Sai định dạng file", data=None)

    # 2. Đọc file vào RAM
    file_bytes = await file.read()
    
    # 3. GỌI WHISPER (Nghe)
    text_result = await transcribe_audio(file_bytes, file.filename)
    if not text_result:
        return DraftOrderResponse(success=False, message="Không nghe rõ âm thanh", data=None)
    
    print(f"DEBUG - Text nghe được: {text_result}")

    # 4. GỌI GPT (Hiểu)
    json_result = extract_order_info(text_result)
    
    if not json_result:
         return DraftOrderResponse(success=False, message="Lỗi phân tích cú pháp", data=None)

    # 5. Ghép thêm text gốc vào để frontend hiển thị
    json_result["raw_text_spoken"] = text_result

    return DraftOrderResponse(
        success=True,
        message="Phân tích thành công",
        data=json_result
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)