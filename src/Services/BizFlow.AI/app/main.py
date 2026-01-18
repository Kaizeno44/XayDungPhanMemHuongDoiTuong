from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware  # <--- [MỚI] Import thư viện CORS
from pydantic import BaseModel
from typing import List, Any, Optional
import os
import google.generativeai as genai

# Import service
from app.services.stt_service import transcribe_audio
from app.services.nlp_service import extract_order_info
from app.services.rag_service import rag_client

app = FastAPI(title="BizFlow AI Service", version="1.0.0")

# --- [MỚI] CẤU HÌNH CORS (BẮT BUỘC CHO MOBILE APP) ---
# Cho phép mọi nguồn (Mobile, Web Admin) gọi vào API này
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Cho phép tất cả (Demo thì để * cho tiện)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MODEL RESPONSE (Đã chuẩn hóa theo Mobile App của Person C) ---
class DraftOrderResponse(BaseModel):
    success: bool
    message: str
    data: Any 

@app.on_event("startup")
async def startup_event():
    # Kiểm tra và cấu hình Gemini
    try:
        api_key = os.getenv("GEMINI_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
            print("✅ Gemini API Key configured successfully")
    except Exception as e:
        print(f"⚠️ Warning: Gemini configuration failed: {e}")

@app.get("/")
def health_check():
    chroma_status = rag_client.check_health()
    return {"service": "AI Service Ready", "chroma_connected": chroma_status is not None}

@app.post("/api/ai/analyze-voice", response_model=DraftOrderResponse)
async def analyze_voice(file: UploadFile = File(...)):
    # 1. Validation
    if not file.filename.lower().endswith(('.wav', '.mp3', '.m4a', '.ogg', '.aac')):
         # Mobile Flutter thường gửi file .m4a hoặc .aac
        return DraftOrderResponse(success=False, message="Định dạng file không hỗ trợ", data=None)

    # 2. Đọc file
    file_bytes = await file.read()
    
    # 3. Speech-to-Text
    text_result = await transcribe_audio(file_bytes, file.filename)
    if not text_result:
        return DraftOrderResponse(success=False, message="Không nghe rõ, vui lòng nói lại", data=None)
    
    print(f"📢 Khách nói: {text_result}")

    # 4. NLP Extract (Lấy intent thô)
    draft_order = extract_order_info(text_result)
    
    if not draft_order or not draft_order.get("items"):
         return DraftOrderResponse(success=False, message="Không hiểu ý định mua hàng", data=draft_order)

    # 5. RAG: Mapping sản phẩm với Database của Person B
    enriched_items = []
    
    for item in draft_order["items"]:
        raw_name = item["product_name"]
        
        # Tìm kiếm trong ChromaDB
        search_result = rag_client.search_product(raw_name)
        
        if search_result:
            item["product_id"] = int(search_result["id"])
            item["product_name"] = search_result["name"]
            item["price"] = search_result["metadata"]["price"]
            item["image_url"] = search_result["metadata"].get("image", "")
            
            item["total_price"] = item["quantity"] * search_result["metadata"]["price"]
            print(f"✅ Mapped: '{raw_name}' -> ID: {search_result['id']}")
        else:
            # Khi rơi vào đây nghĩa là sản phẩm không có trong DB hoặc bị filter do sai lệch quá lớn
            item["product_id"] = None
            item["price"] = 0
            item["total_price"] = 0
            item["note"] = "Không tìm thấy sản phẩm này trong kho VLXD"
            print(f"❌ Not found/Ignored: '{raw_name}'")
            
        enriched_items.append(item)

    draft_order["items"] = enriched_items
    draft_order["raw_text_spoken"] = text_result

    return DraftOrderResponse(
        success=True,
        message="Đã xử lý xong yêu cầu",
        data=draft_order
    )