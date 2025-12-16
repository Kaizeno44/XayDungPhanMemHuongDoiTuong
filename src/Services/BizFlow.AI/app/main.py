from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List
from app.services.rag_service import rag_client # Import service vừa viết

app = FastAPI(title="BizFlow AI Service", version="1.0.0")

# --- MODEL DỮ LIỆU (Contract với Mobile & Order Service) ---
class OrderItemDraft(BaseModel):
    product_name_spoken: str  # Tên người dùng nói
    sku: str                  # Mã SKU tìm được (Giả lập)
    quantity: int
    unit: str                 # Đơn vị tính

class DraftOrderResponse(BaseModel):
    success: bool
    message: str
    data: dict | None

# --- API ENDPOINTS ---

@app.get("/")
def health_check():
    # Kiểm tra luôn kết nối ChromaDB khi check health
    chroma_status = rag_client.check_health()
    return {
        "service": "AI Service Running",
        "chroma_db_connected": chroma_status is not None,
        "chroma_latency": chroma_status
    }

@app.post("/api/ai/speech-to-text", response_model=DraftOrderResponse)
async def speech_to_text(file: UploadFile = File(...)):
    """
    1. Nhận file âm thanh.
    2. (Mock) Giả vờ convert text -> Tìm sản phẩm.
    3. Trả về JSON để Frontend điền form.
    """
    
    # Validation file (chỉ cho phép đuôi âm thanh)
    if not file.filename.lower().endswith(('.wav', '.mp3', '.m4a', '.ogg')):
        return DraftOrderResponse(
            success=False, 
            message="Định dạng file không hỗ trợ. Hãy dùng .wav hoặc .mp3", 
            data=None
        )

    # --- ĐÂY LÀ MOCK DATA (GIẢ LẬP) ---
    # Tình huống: Khách nói "Cho anh 5 bao xi măng Hà Tiên và 2 khối cát vàng"
    
    mock_result = {
        "raw_text": "Lấy cho anh 5 bao xi măng Hà Tiên và 2 khối cát vàng nợ nhé",
        "intent": "create_order",
        "is_debt": True, # Phát hiện từ khóa "nợ"
        "customer_name": "Anh Khách Lẻ", # Chưa định danh được thì để chung
        "items": [
            {
                "product_name_spoken": "xi măng Hà Tiên",
                "sku": "XM_HATIEN_01", # Giả định đã tìm thấy trong ChromaDB
                "quantity": 5,
                "unit": "bao"
            },
            {
                "product_name_spoken": "cát vàng",
                "sku": "CAT_VANG_XAY",
                "quantity": 2,
                "unit": "khoi"
            }
        ]
    }

    return DraftOrderResponse(
        success=True,
        message="Phân tích giọng nói thành công (Mock)",
        data=mock_result
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)