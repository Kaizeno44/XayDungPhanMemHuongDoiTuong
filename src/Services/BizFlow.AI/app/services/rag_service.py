import chromadb
import os
import logging

# Lấy cấu hình từ biến môi trường (được set trong docker-compose)
CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = os.getenv("CHROMA_PORT", "8000")

class RagService:
    def __init__(self):
        self.client = None
        self.collection = None
        try:
            logging.info(f"Đang kết nối ChromaDB tại {CHROMA_HOST}:{CHROMA_PORT}...")
            # Kết nối đến HTTP Server của Chroma (chạy trên Docker)
            self.client = chromadb.HttpClient(host=CHROMA_HOST, port=int(CHROMA_PORT))
            
            # Tạo hoặc lấy collection (giống như Table trong SQL)
            self.collection = self.client.get_or_create_collection(name="products_collection")
            logging.info("Kết nối ChromaDB thành công!")
        except Exception as e:
            logging.error(f"Lỗi kết nối ChromaDB: {e}")

    def check_health(self):
        """Kiểm tra xem ChromaDB có sống không"""
        if self.client:
            return self.client.heartbeat() # Trả về số nanosecond hệ thống
        return None

# Tạo instance dùng chung
rag_client = RagService()