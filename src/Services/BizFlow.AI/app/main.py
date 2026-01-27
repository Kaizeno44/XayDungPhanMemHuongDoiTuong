from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Any, Optional
import os
import asyncio # <--- [MỚI] Dùng để chạy tác vụ nền
import google.generativeai as genai

# Import service
from app.services.stt_service import transcribe_audio
from app.services.nlp_service import extract_order_info
from app.services.rag_service import rag_client

# Import hàm đồng bộ dữ liệu (từ file seed_data.py bạn đã có)
from app.seed_data import run_seed 

app = FastAPI(title="BizFlow AI Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DraftOrderResponse(BaseModel):
    success: bool
    message: str
    data: Any 

# --- [MỚI] HÀM CHẠY NGẦM ĐỊNH KỲ ---
async def scheduled_sync_data():
    """Hàm này sẽ chạy vô tận, cứ 5 phút (300s) lại đồng bộ dữ liệu 1 lần"""
    while True:
        print("⏰ [Auto-Sync] Bắt đầu chu trình đồng bộ dữ liệu tự động...")
        try:
            # run_seed là hàm đồng bộ (sync), cần chạy trong thread riêng để không chặn API
            await asyncio.to_thread(run_seed)
            print("✅ [Auto-Sync] Đồng bộ hoàn tất.")
        except Exception as e:
            print(f"❌ [Auto-Sync] Lỗi: {e}")
        
        # Nghỉ 5 phút trước khi chạy lại (300 giây)
        await asyncio.sleep(300) 

@app.on_event("startup")
async def startup_event():
    # 1. Cấu hình Gemini
    try:
        api_key = os.getenv("GEMINI_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
            print("✅ Gemini API Key configured successfully")
    except Exception as e:
        print(f"⚠️ Warning: Gemini configuration failed: {e}")

    # 2. [MỚI] Kích hoạt chạy ngầm (Chờ 10s cho Product API sống rồi mới chạy)
    asyncio.create_task(delayed_start_sync())

async def delayed_start_sync():
    await asyncio.sleep(10) # Đợi 10s lúc khởi động
    asyncio.create_task(scheduled_sync_data())


# --- [MỚI] API ĐỂ BẠN GỌI THỦ CÔNG KHI CẦN (TRIGGER) ---
# Gọi POST http://localhost:5005/api/ai/sync-db để ép AI cập nhật ngay lập tức
@app.post("/api/ai/sync-db")
async def force_sync_db(background_tasks: BackgroundTasks):
    # Chạy ở background để trả về response ngay cho người dùng đỡ phải đợi
    background_tasks.add_task(run_seed)
    return {"message": "Đã nhận lệnh! Quá trình đồng bộ đang chạy ngầm..."}


@app.get("/")
def health_check():
    chroma_status = rag_client.check_health()
    return {"service": "AI Service Ready", "chroma_connected": chroma_status is not None}

# ... (Giữ nguyên các API analyze-voice cũ của bạn ở dưới) ...
@app.post("/api/ai/analyze-voice", response_model=DraftOrderResponse)
async def analyze_voice(file: UploadFile = File(...)):
    # ... (Giữ nguyên code cũ) ...
    # Copy lại đoạn code analyze_voice cũ vào đây
    # 1. Validation
    if not file.filename.lower().endswith(('.wav', '.mp3', '.m4a', '.ogg', '.aac')):
        return DraftOrderResponse(success=False, message="Định dạng file không hỗ trợ", data=None)

    # 2. Đọc file
    file_bytes = await file.read()
    
    # 3. Speech-to-Text
    text_result = await transcribe_audio(file_bytes, file.filename)
    if not text_result:
        return DraftOrderResponse(success=False, message="Không nghe rõ, vui lòng nói lại", data=None)
    
    print(f"📢 Khách nói: {text_result}")

    # 4. NLP Extract
    draft_order = extract_order_info(text_result)
    
    if not draft_order or not draft_order.get("items"):
         return DraftOrderResponse(success=False, message="Không hiểu ý định mua hàng", data=draft_order)

    # 5. RAG
    enriched_items = []
    for item in draft_order["items"]:
        raw_name = item["product_name"]
        search_result = rag_client.search_product(raw_name)
        
        if search_result:
            item["product_id"] = int(search_result["id"])
            item["product_name"] = search_result["name"]
            item["price"] = search_result["metadata"]["price"]
            item["image_url"] = search_result["metadata"].get("image", "")
            item["total_price"] = item["quantity"] * search_result["metadata"]["price"]
            print(f"✅ Mapped: '{raw_name}' -> ID: {search_result['id']}")
        else:
            item["product_id"] = None
            item["price"] = 0
            item["total_price"] = 0
            item["note"] = "Không tìm thấy sản phẩm này"
            print(f"❌ Not found/Ignored: '{raw_name}'")

        enriched_items.append(item)

    draft_order["items"] = enriched_items
    draft_order["raw_text_spoken"] = text_result

    return DraftOrderResponse(success=True, message="Đã xử lý xong yêu cầu", data=draft_order)