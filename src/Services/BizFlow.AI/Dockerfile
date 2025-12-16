# 1. Chọn môi trường Python nhẹ
FROM python:3.10-slim

# 2. Tạo thư mục làm việc trong container
WORKDIR /app

# 3. Copy file requirements và cài thư viện trước (để tận dụng cache Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy toàn bộ code vào
COPY . .

# 5. Mở port 8000
EXPOSE 8000

# 6. Lệnh chạy server
# Lưu ý đường dẫn app.main vì file main.py nằm trong thư mục app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]