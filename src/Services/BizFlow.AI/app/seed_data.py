from app.services.rag_service import rag_client
import time

# [QUAN TRỌNG] Danh sách này PHẢI GIỐNG HỆT dữ liệu bên Product Service (MySQL)
# Hãy bảo Person B gửi cho bạn danh sách sản phẩm họ đã tạo.
# Dưới đây là danh sách mẫu chuẩn cho Demo VLXD:

sample_products = [
    # Nhóm Xi măng
    {
        "id": "10",  # ID trong MySQL thường bắt đầu từ 1
        "name": "Xi măng Hà Tiên Đa Dụng", 
        "unit": "bao", 
        "price": 88000, 
        "code": "XM_HT",
        "image": "https://vatlieuxaydung.com/images/ximang-hatien.jpg" 
    },
    {
        "id": "11", 
        "name": "Xi măng Nghi Sơn PCB40", 
        "unit": "bao", 
        "price": 82000, 
        "code": "XM_NS",
        "image": "https://vatlieuxaydung.com/images/ximang-nghison.jpg"
    },
    
    # Nhóm Cát - Đá
    {
        "id": "3", 
        "name": "Cát vàng xây tô (Hạt lớn)", 
        "unit": "khối", 
        "price": 450000, 
        "code": "CAT_VANG",
        "image": ""
    },
    {
        "id": "4", 
        "name": "Đá 1x2 Xanh (Đổ bê tông)", 
        "unit": "khối", 
        "price": 380000, 
        "code": "DA_12",
        "image": ""
    },
    
    # Nhóm Sắt Thép
    {
        "id": "5", 
        "name": "Thép cuộn Pomina Ø6", 
        "unit": "kg", 
        "price": 18500, 
        "code": "THEP_POMINA",
        "image": ""
    },
    {
        "id": "6", 
        "name": "Thép thanh vằn Hòa Phát CB300", 
        "unit": "cây", 
        "price": 115000, 
        "code": "THEP_HP",
        "image": ""
    },

    # Nhóm Gạch
    {
        "id": "7", 
        "name": "Gạch ống 4 lỗ Tuynel", 
        "unit": "viên", 
        "price": 1300, 
        "code": "GACH_ONG",
        "image": ""
    },

    {
        "id": "8", 
        "name": "Tôn lạnh mạ màu Hoa Sen", 
        "unit": "tấm", 
        "price": 185000, 
        "code": "TON_LANH",
        "image": ""
    },

    {
        "id": "14", 
        "name": "Tôn lạnh mạ màu Hoa Hòe", 
        "unit": "tấm", 
        "price": 190000, 
        "code": "TON_LANH2",
        "image": ""
    }
]

def run_seed():
    print("⏳ Đang đợi ChromaDB khởi động...")
    time.sleep(3) 
    
    print(f"🚀 Đang nạp {len(sample_products)} sản phẩm chuẩn vào Vector DB...")
    rag_client.add_products(sample_products)
    
    print("✅ Đồng bộ dữ liệu hoàn tất!")
    print("👉 AI Service đã sẵn sàng phục vụ Mobile App.")

if __name__ == "__main__":
    run_seed()