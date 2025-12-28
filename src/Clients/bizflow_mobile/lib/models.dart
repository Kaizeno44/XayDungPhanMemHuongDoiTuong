// ================= CART ITEM =================
class CartItem {
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {"productId": productId, "unitId": unitId, "quantity": quantity};
  }
}

// ================= CUSTOMER =================
class Customer {
  final String id;
  final String name;

  Customer({required this.id, required this.name});

  // Thêm factory để parse an toàn nếu sau này cần
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Khách hàng',
    );
  }
}

// ================= PRODUCT (CẬP NHẬT QUAN TRỌNG) =================
class Product {
  final int id;
  final String name;
  final double price;
  final int unitId;
  final String unitName;
  final String? imageUrl; // Thêm ảnh cho đẹp

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unitId,
    required this.unitName,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 1. Khởi tạo giá trị mặc định
    double parsedPrice = 0.0;
    int parsedUnitId = 0;
    String parsedUnitName = json['baseUnit'] ?? 'Đơn vị';

    // 2. Logic thông minh: Tìm giá trong productUnits
    // (Vì API của bạn giấu giá bên trong danh sách con này)
    if (json['productUnits'] != null) {
      final units = json['productUnits'] as List;
      if (units.isNotEmpty) {
        // Lấy đơn vị đầu tiên (thường là đơn vị cơ bản)
        final firstUnit = units[0];

        // Lấy ID đơn vị
        parsedUnitId = firstUnit['id'] ?? 0;

        // Lấy Tên đơn vị
        parsedUnitName = firstUnit['unitName'] ?? parsedUnitName;

        // Lấy Giá (Xử lý an toàn cả int và double)
        if (firstUnit['price'] != null) {
          parsedPrice = (firstUnit['price'] is int)
              ? (firstUnit['price'] as int).toDouble()
              : (firstUnit['price'] as double);
        }
      }
    }
    // Fallback: Nếu không có productUnits, thử tìm giá ở root (phòng hờ)
    else if (json['price'] != null) {
      parsedPrice = (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as double);
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Sản phẩm không tên",
      price: parsedPrice,
      unitId: parsedUnitId,
      unitName: parsedUnitName,
      imageUrl: json['imageUrl'], // Lấy link ảnh nếu có
    );
  }
}
