import google.generativeai as genai
import json
import os

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def extract_order_info(text: str):
    """
    Trích xuất thông tin đơn hàng từ giọng nói.
    """
    try:
        # Cấu hình để Gemini BẮT BUỘC trả về JSON
        generation_config = {
            "temperature": 0.1,
            "response_mime_type": "application/json"
        }

        model = genai.GenerativeModel(
            "gemini-flash-latest", 
            generation_config=generation_config
        )
    
        prompt = f"""
        Bạn là trợ lý bán hàng chuyên về Vật liệu xây dựng (VLXD). 
        Nhiệm vụ: Trích xuất thông tin đơn hàng từ câu nói: "{text}"

        Lưu ý QUAN TRỌNG:
        1. Chỉ trích xuất các sản phẩm thuộc nhóm: Xi măng, Cát, Đá, Gạch, Sắt, Thép, Tôn, Sơn, Ống nước.
        2. Nếu khách hàng mua đồ ăn (bánh mì, cơm...), quần áo, hoặc thứ không liên quan đến xây dựng:
           -> Hãy BỎ QUA sản phẩm đó (không đưa vào danh sách items).
           -> Nếu cả câu nói không có sản phẩm VLXD nào, hãy trả về danh sách "items" rỗng.

        Yêu cầu Output JSON schema:
        {{
            "intent": "create_order",
            "customer_name": "Tên khách hàng hoặc null",
            "customer_phone": "Số điện thoại hoặc null",
            "payment_method": "Cash (Tiền mặt) hoặc Debt (Ghi nợ/Nợ). Mặc định Cash",
            "items": [
                {{
                    "product_name": "Tên sản phẩm",
                    "quantity": int,
                    "unit": "Đơn vị tính (bao/kg/khối...)"
                }}
            ]
        }}
        """
        
        response = model.generate_content(prompt)
        return json.loads(response.text.replace("```json", "").replace("```", "").strip())

    except Exception as e:
        print(f"NLP Error: {e}")
        print(f"============== LỖI GEMINI NLP ==============")
        return {"intent": "error", "items": []}