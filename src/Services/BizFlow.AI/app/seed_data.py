from app.services.rag_service import rag_client
import time

# Dữ liệu này PHẢI KHỚP với Database của Person B (Product Service)
# ID 101, 102... là giả định, bạn hãy thống nhất với team Mobile
sample_products = [
    {"id": "101", "name": "Xi măng Hà Tiên đa dụng", "unit": "bao", "price": 85000, "code": "XM_HT"},
    {"id": "102", "name": "Xi măng Nghi Sơn", "unit": "bao", "price": 82000, "code": "XM_NS"},
    {"id": "103", "name": "Xi măng trắng", "unit": "kg", "price": 12000, "code": "XM_TR"},
    {"id": "201", "name": "Cát vàng xây tô", "unit": "khối", "price": 450000, "code": "CAT_VANG"},
    {"id": "202", "name": "Cát san lấp", "unit": "khối", "price": 200000, "code": "CAT_DEN"},
    {"id": "301", "name": "Đá 1x2 bê tông", "unit": "khối", "price": 380000, "code": "DA_12"},
    {"id": "401", "name": "Gạch ống 4 lỗ", "unit": "viên", "price": 1200, "code": "GACH_ONG"},
    {"id": "501", "name": "Thép cuộn Pomina", "unit": "kg", "price": 18000, "code": "THEP_CUON"}
]

def run_seed():
    print("⏳ Đang chờ ChromaDB khởi động...")
    time.sleep(2)
    print("🚀 Bắt đầu nạp dữ liệu vector...")
    rag_client.add_products(sample_products)
    
    # Test thử luôn
    print("\n🔎 Test tìm kiếm: 'lấy bao xi măng hà tiên'")
    result = rag_client.search_product("lấy bao xi măng hà tiên")
    print(f"👉 Kết quả: {result}")

if __name__ == "__main__":
    run_seed()