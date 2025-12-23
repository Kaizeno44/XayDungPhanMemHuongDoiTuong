from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Any
import os
import google.generativeai as genai

# Import 2 service vừa viết
from app.services.stt_service import transcribe_audio
from app.services.nlp_service import extract_order_info
from app.services.rag_service import rag_client # Import client đã nâng cấp

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
    # 1. Validation & STT (Giữ nguyên)
    if not file.filename.lower().endswith(('.wav', '.mp3', '.m4a', '.ogg')):
        return DraftOrderResponse(success=False, message="Sai định dạng file", data=None)
    
    file_bytes = await file.read()
    text_result = await transcribe_audio(file_bytes, file.filename)
    
    if not text_result:
        return DraftOrderResponse(success=False, message="Không nghe rõ âm thanh", data=None)
    
    print(f"📢 Text nghe được: {text_result}")

    # 2. NLP Extract (Giữ nguyên - Lấy ra danh sách sản phẩm thô)
    draft_order = extract_order_info(text_result)
    
    if not draft_order or not draft_order.get("items"):
         # Nếu Gemini không trích xuất được gì, trả về lỗi luôn
         return DraftOrderResponse(success=False, message="Không hiểu ý định mua hàng", data=draft_order)

    # ==================================================================
    # 3. RAG: ĐI TÌM ID SẢN PHẨM TRONG CHROMADB (PHẦN MỚI CỦA TUẦN 4)
    # ==================================================================
    enriched_items = []
    
    for item in draft_order["items"]:
        raw_name = item["product_name"]
        
        # Tìm trong ChromaDB (Vector Search)
        # Ví dụ: raw_name="xi măng hà tiên" -> Tìm thấy ID="101"
        search_result = rag_client.search_product(raw_name)
        
        if search_result:
            # Nếu tìm thấy, bổ sung thông tin ID và Giá vào
            item["product_id"] = search_result["id"]
            item["official_name"] = search_result["name"]
            item["unit_price"] = search_result["metadata"]["price"]
            
            # Tính thành tiền tạm tính (cho App hiển thị chơi)
            item["total_price"] = item["quantity"] * search_result["metadata"]["price"]
            
            print(f"✅ Mapped: '{raw_name}' -> ID: {search_result['id']}")
        else:
            # Nếu không tìm thấy trong DB
            item["product_id"] = None
            item["note"] = "Không tìm thấy sản phẩm này trong kho"
            print(f"❌ Not found: '{raw_name}'")
            
        enriched_items.append(item)

    # Cập nhật lại danh sách items đã có ID
    draft_order["items"] = enriched_items
    draft_order["raw_text_spoken"] = text_result

    return DraftOrderResponse(
        success=True,
        message="Phân tích và tìm kiếm sản phẩm thành công",
        data=draft_order
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)