import os
import time
import requests
from app.services.rag_service import rag_client

# [CẬP NHẬT] Đổi sang port 5002 và thêm pageSize lớn để lấy hết dữ liệu
# Lưu ý: host.docker.internal dùng để container gọi ra máy host (nơi chạy ProductAPI)
PRODUCT_API_URL = os.getenv("PRODUCT_API_URL", "http://host.docker.internal:5002/api/Products?pageSize=1000")

def get_products_from_api():
    print(f"🔌 Đang gọi API: {PRODUCT_API_URL}...")
    products = []
    
    try:
        response = requests.get(PRODUCT_API_URL, timeout=10)
        
        if response.status_code == 200:
            json_response = response.json()
            
            # [QUAN TRỌNG] Xử lý phân trang
            # API của bạn trả về: { "totalItems": 10, "data": [...] }
            # Nên cần lấy key "data" (hoặc "Data" tùy vào config JSON của C#)
            data_list = json_response.get("data", json_response.get("Data", []))
            
            if not isinstance(data_list, list):
                print(f"⚠️ Cấu trúc JSON không đúng mong đợi: {json_response.keys()}")
                return []

            for item in data_list:
                # Tìm đơn vị tính gốc (IsBaseUnit = true)
                base_unit = None
                if "productUnits" in item and item["productUnits"]:
                    # Lấy unit có isBaseUnit = true, nếu không có thì lấy cái đầu tiên
                    base_unit = next((u for u in item["productUnits"] if u.get("isBaseUnit")), item["productUnits"][0])
                
                price = base_unit["price"] if base_unit else 0
                unit_name = base_unit["unitName"] if base_unit else "cái"
                
                # Map dữ liệu sang chuẩn Vector DB
                products.append({
                    "id": str(item["id"]),
                    "name": item["name"],
                    "unit": unit_name,
                    "price": float(price),
                    "code": item["sku"], 
                    "image": item.get("imageUrl", "")
                })
            
            print(f"✅ Đã lấy thành công {len(products)} sản phẩm từ API.")
        else:
            print(f"❌ Lỗi API: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Không thể kết nối đến Product API: {e}")
        print("💡 Gợi ý: Hãy chắc chắn ProductAPI đang chạy ở port 5002.")

    return products

def run_seed():
    print("⏳ Đang đợi dịch vụ khởi động (5s)...")
    time.sleep(5) 
    
    api_products = get_products_from_api()
    
    if not api_products:
        print("⚠️ Không có dữ liệu để nạp. Bỏ qua.")
        return

    print(f"🚀 Đang nạp {len(api_products)} sản phẩm vào Vector DB...")
    rag_client.add_products(api_products)
    
    print("✅ Đồng bộ dữ liệu API -> ChromaDB hoàn tất!")

if __name__ == "__main__":
    run_seed()