# TUẦN 1 PERSON D
## Nhiệm vụ:
**Tìm hiểu API OpenAI/Gemini hoặc Model Local (Whisper):**
* Đã thêm openai-whisper vào requirements.txt.
* Đã bật ffmpeg trong Dockerfile.
* Đã viết code model = whisper.load_model("base") và model.transcribe trong main.py.
* Hệ thống chạy Local hoàn toàn trong Docker, không tốn tiền API.

**Xác định Input: File âm thanh (.wav/.mp3):**
* Trong main.py, đã khai báo endpoint nhận file: UploadFile.
* Code đã xử lý việc lưu file upload thành temp_audio.mp3 để thư viện Whisper đọc được.
* Đã test bằng cách upload file thực tế qua Swagger UI.

**Xác định Output: Chuỗi JSON:**
* Trong file main.py, đã viết class DraftOrderResponse và OrderItem.
* Định nghĩa Class DraftOrderResponse (Pydantic model) trả về đúng chuẩn JSON.
* Đã quy định rõ API trả về cái gì: customer_name, danh sách items (có sku, qty, unit).
* Đây chính là cái gọi là API Contract (Hợp đồng giao tiếp) để Person C (Order Service) biết đường mà gọi bạn.
* Trường raw_text trong JSON bây giờ trả về kết quả thật do AI nghe được.

**Setup project Python FastAPI rỗng, chạy thử Docker cho Python:**
* Tạo cấu trúc thư mục src/Services/AI_DraftOrder.
* Tạo file main.py với thư viện FastAPI.
* Tạo file Dockerfile và requirements.txt
* Thêm cấu hình ai_service vào docker-compose.yml.
* Chạy thành công lệnh docker-compose up và thấy dòng chữ Uvicorn running....

# Cách lấy code
git clone về máy rồi chạy lệnh: **docker-compose up**

check thử BizFlow AI Service trong: **http://localhost:8000/docs**

<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/b4cfb365-6179-4e08-9441-921cf6e0f4cb" />
