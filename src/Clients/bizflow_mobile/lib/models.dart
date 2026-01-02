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

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['fullName'] ?? json['name'] ?? 'Khách hàng',
    );
  }
}

// ================= PRODUCT (ĐÃ SỬA LỖI) =================
class Product {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<ProductUnit> productUnits;
  double inventoryQuantity; // Thêm trường tồn kho

  Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.productUnits,
    this.inventoryQuantity = 0.0, // Khởi tạo giá trị mặc định
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var unitsJson = json['productUnits'] as List? ?? []; // Xử lý null an toàn
    List<ProductUnit> units = unitsJson
        .map((e) => ProductUnit.fromJson(e))
        .toList();

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      productUnits: units,
      inventoryQuantity: (json['inventory']?['quantity'] as num?)?.toDouble() ?? 0.0, // Lấy tồn kho từ API
    );
  }

  // Phương thức copyWith để cập nhật sản phẩm
  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    List<ProductUnit>? productUnits,
    double? inventoryQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      productUnits: productUnits ?? this.productUnits,
      inventoryQuantity: inventoryQuantity ?? this.inventoryQuantity,
    );
  }

  // --- LOGIC MỚI: Lấy đơn vị mặc định (Base Unit) ---
  ProductUnit? get _defaultUnit {
    if (productUnits.isEmpty) return null;
    // Ưu tiên lấy đơn vị cơ bản, nếu không có thì lấy cái đầu tiên
    return productUnits.firstWhere(
      (u) => u.isBaseUnit,
      orElse: () => productUnits.first,
    );
  }

  // Sửa lỗi: Trả về 0.0 nếu không có đơn vị, thay vì null
  double get price => _defaultUnit?.price ?? 0.0;

  // Sửa lỗi: Trả về ID của đơn vị mặc định
  int get unitId => _defaultUnit?.id ?? 0;

  // Sửa lỗi: Trả về Tên của đơn vị mặc định
  String get unitName => _defaultUnit?.unitName ?? '';
}

// ================= PRODUCT UNIT =================
class ProductUnit {
  final int id;
  final String unitName;
  final double price;
  final bool isBaseUnit;

  ProductUnit({
    required this.id,
    required this.unitName,
    required this.price,
    required this.isBaseUnit,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: json['id'] ?? 0,
      unitName: json['unitName'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // Parse an toàn
      isBaseUnit: json['isBaseUnit'] ?? false,
    );
  }
}

// ================= HELPER CLASSES =================
class ProductPriceResult {
  final double price;
  final String unitName;

  ProductPriceResult({required this.price, required this.unitName});

  factory ProductPriceResult.fromJson(Map<String, dynamic> json) {
    return ProductPriceResult(
      price: (json['price'] as num).toDouble(),
      unitName: json['unitName'],
    );
  }
}

class SimpleCheckStockResult {
  final bool isEnough;
  final String message;

  SimpleCheckStockResult({required this.isEnough, required this.message});

  factory SimpleCheckStockResult.fromJson(Map<String, dynamic> json) {
    return SimpleCheckStockResult(
      isEnough: json['isEnough'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
