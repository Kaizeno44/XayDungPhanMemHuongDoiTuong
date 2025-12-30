import chromadb
import os
import logging
from typing import List, Dict

# Lấy cấu hình từ docker-compose
CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = os.getenv("CHROMA_PORT", "8000")

class RagService:
    def __init__(self):
        self.client = None
        self.collection = None
        try:
            logging.info(f"Đang kết nối ChromaDB tại {CHROMA_HOST}:{CHROMA_PORT}...")
            self.client = chromadb.HttpClient(host=CHROMA_HOST, port=int(CHROMA_PORT))
            
            # Tạo collection với thuật toán cosine similarity
            self.collection = self.client.get_or_create_collection(
                name="products_collection",
                metadata={"hnsw:space": "cosine"} 
            )
            logging.info("Kết nối ChromaDB thành công!")
        except Exception as e:
            logging.error(f"Lỗi kết nối ChromaDB: {e}")

    def check_health(self):
        if self.client:
            return self.client.heartbeat()
        return None

    def add_products(self, products: List[Dict]):
        if not self.collection: return
        
        ids = [str(p["id"]) for p in products]
        documents = [p["name"] for p in products]
        
        # [MỚI] Lưu thêm image và code vào metadata
        metadatas = [{
            "price": p["price"], 
            "unit": p["unit"], 
            "code": p.get("code", ""),
            "image": p.get("image", "")
        } for p in products]

        self.collection.upsert(
            ids=ids,
            documents=documents,
            metadatas=metadatas
        )
        print(f"✅ Đã nạp {len(ids)} sản phẩm.")

    def search_product(self, query_text: str, n_results=1):
        if not self.collection: return None

        results = self.collection.query(
            query_texts=[query_text],
            n_results=n_results
        )
        
        if results and results['ids'] and len(results['ids'][0]) > 0:
            # Trả về đầy đủ thông tin
            return {
                "id": results['ids'][0][0],
                "name": results['documents'][0][0],
                "metadata": results['metadatas'][0][0], # Chứa price, unit, image
                "distance": results['distances'][0][0]
            }
        return None

rag_client = RagService()