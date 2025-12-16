from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(title="BizFlow AI Service", version="1.0.0")

# --- 1. Định nghĩa cấu trúc dữ liệu trả về (Output Contract) ---
# Đây là phần quan trọng nhất để khớp với Person C

class DraftOrderItem(BaseModel):
    product_name_detected: str  # Tên sản phẩm nghe được (VD: "Xi măng Hà Tiên")
    suggested_product_id: int   # ID sản phẩm tìm thấy trong DB (Giả lập)
    suggested_unit_id: int      # ID đơn vị tính
    quantity: int
    unit_name: str              # VD: "bao"

class DraftOrderResponse(BaseModel):
    customer_name_detected: str
    is_debt: bool               # Có nợ hay không
    items: List[DraftOrderItem]
    raw_text: str               # Nội dung văn bản sau khi STT

# --- 2. API Endpoint ---

@app.get("/")
def read_root():
    return {"message": "BizFlow AI Service is running!"}

@app.post("/api/ai/analyze-order", response_model=DraftOrderResponse)
async def analyze_voice_order(file: UploadFile = File(...)):
    """
    API nhận file âm thanh (.wav, .mp3), 
    Giả lập việc phân tích và trả về đơn hàng nháp.
    """
    
    # Kiểm tra định dạng file sơ bộ
    if not file.filename.endswith(('.wav', '.mp3', '.m4a')):
        raise HTTPException(status_code=400, detail="File format not supported")

    # TODO: Tuần sau sẽ code logic STT (Whisper) ở đây.
    # Hiện tại trả về dữ liệu giả (Hardcode) để test luồng.

    mock_response = DraftOrderResponse(
        customer_name_detected="Anh Nam",
        is_debt=True,
        raw_text="Bán cho anh Nam 5 bao xi măng Hà Tiên ghi nợ nhé",
        items=[
            DraftOrderItem(
                product_name_detected="Xi măng Hà Tiên",
                suggested_product_id=101,  # ID giả định
                suggested_unit_id=1,       # ID đơn vị giả định
                quantity=5,
                unit_name="bao"
            )
        ]
    )
    
    return mock_response

# Chạy server (nếu chạy trực tiếp bằng python main.py)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)