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
        Bạn là trợ lý bán hàng VLXD. Hãy trích xuất thông tin từ câu nói sau thành JSON:
        "{text}"

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
        
        model = genai.GenerativeModel('gemini-flash-latest')
        response = model.generate_content(prompt)
        return json.loads(response.text.replace("```json", "").replace("```", "").strip())

    except Exception as e:
        print(f"NLP Error: {e}")
        print(f"============== LỖI GEMINI NLP ==============")
        return {"intent": "error", "items": []}