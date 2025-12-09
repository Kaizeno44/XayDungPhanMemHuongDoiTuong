# Sử dụng Python nhẹ nhất
FROM python:3.10-slim

# Thiết lập thư mục làm việc
WORKDIR /app

# Cài đặt các dependencies hệ thống nếu cần (cho thư viện âm thanh)
RUN apt-get update && apt-get install -y ffmpeg

# Copy file requirements và cài đặt thư viện
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ code vào
COPY . .

# Mở port 8000
EXPOSE 8000

# Lệnh chạy server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]