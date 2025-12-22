import google.generativeai as genai
import os
import tempfile
import mimetypes # <--- Thêm thư viện này

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

async def transcribe_audio(file_bytes: bytes, filename: str) -> str:
    """
    Dùng Gemini 1.5 Flash để nghe file âm thanh.
    """
    temp_path = None
    try:
        # 1. Xác định MIME type chuẩn dựa vào đuôi file
        mime_type, _ = mimetypes.guess_type(filename)
        if not mime_type:
            # Fallback nếu không đoán được
            if filename.endswith(".mp3"): mime_type = "audio/mpeg"
            elif filename.endswith(".wav"): mime_type = "audio/wav"
            elif filename.endswith(".m4a"): mime_type = "audio/mp4"
            else: mime_type = "audio/mpeg" # Mặc định
            
        print(f"DEBUG: Đang xử lý file {filename} với mime_type={mime_type}")

        # 2. Tạo file tạm
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(filename)[1]) as tmp:
            tmp.write(file_bytes)
            temp_path = tmp.name

        # 3. Upload file lên Google
        audio_file = genai.upload_file(path=temp_path, mime_type=mime_type)

        # 4. Gọi Gemini
        model = genai.GenerativeModel("gemini-flash-latest")
        response = model.generate_content([
            "Hãy nghe file âm thanh này và chép lại chính xác lời nói (Transcribe). Chỉ trả về text, không thêm mô tả.",
            audio_file
        ])

        print(f"DEBUG: Kết quả Gemini: {response.text}")
        return response.text.strip()

    except Exception as e:
        print(f"============== LỖI GEMINI STT ==============")
        print(e) # <--- Log lỗi sẽ hiện ở đây
        print(f"============================================")
        return ""
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)