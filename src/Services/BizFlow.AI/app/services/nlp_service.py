import google.generativeai as genai
import os
import json

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def extract_order_info(text: str):
    """
    Dùng Gemini 1.5 Flash để trích xuất JSON từ văn bản.
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
        Bạn là AI bán hàng VLXD. Hãy phân tích câu nói sau thành JSON đơn hàng:
        "{text}"

        Yêu cầu Output JSON schema:
        {{
            "intent": "create_order",
            "customer_name": "string (Tên khách hoặc 'Khách lẻ')",
            "is_debt": bool (true nếu có từ khóa 'nợ'),
            "items": [
                {{
                    "product_name": "string",
                    "quantity": int,
                    "unit": "string"
                }}
            ]
        }}
        """

        response = model.generate_content(prompt)
        
        # Vì đã set response_mime_type="application/json", ta parse thẳng luôn
        return json.loads(response.text)

    except Exception as e:
        print(f"============== LỖI GEMINI NLP ==============")
        print(e)
        return None