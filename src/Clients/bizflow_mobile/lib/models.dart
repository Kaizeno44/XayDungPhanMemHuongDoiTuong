// lib/models.dart

// ================= CART ITEM =================
class CartItem {
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double price;
  int quantity;
  final double maxStock; // 👈 MỚI: Lưu trữ tồn kho tối đa

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.price,
    this.quantity = 1,
    required this.maxStock, // 👈 Bắt buộc truyền vào
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {"productId": productId, "unitId": unitId, "quantity": quantity};
  }
}

// ================= CUSTOMER =================
class Customer {
  String id;
  final String name;
  final String phone;
  final String address;
  double currentDebt;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.currentDebt = 0.0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['fullName'] ?? json['name'] ?? 'Khách lẻ',
      phone: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
      currentDebt: (json['currentDebt'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': name,
      'phoneNumber': phone,
      'address': address,
      'currentDebt': 0,
    };
  }
}

// ================= PRODUCT =================
class Product {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<ProductUnit> productUnits;
  double inventoryQuantity;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.productUnits,
    this.inventoryQuantity = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var unitsJson = json['productUnits'] as List? ?? [];
    List<ProductUnit> units = unitsJson
        .map((e) => ProductUnit.fromJson(e))
        .toList();

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      productUnits: units,
      inventoryQuantity:
          (json['inventory']?['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

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

  ProductUnit? get _defaultUnit {
    if (productUnits.isEmpty) return null;
    return productUnits.firstWhere(
      (u) => u.isBaseUnit,
      orElse: () => productUnits.first,
    );
  }

  double get basePrice => _defaultUnit?.price ?? 0.0;
  int get unitId => _defaultUnit?.id ?? 0;
  String get unitName => _defaultUnit?.unitName ?? '';
  double get price => basePrice;
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
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isBaseUnit: json['isBaseUnit'] ?? false,
    );
  }
}

// ================= HELPER CLASSES =================
class ProductPriceResult {
  final int productId;
  final int unitId;
  final double price;

  ProductPriceResult({
    required this.productId,
    required this.unitId,
    required this.price,
  });

  factory ProductPriceResult.fromJson(Map<String, dynamic> json) {
    return ProductPriceResult(
      productId: json['productId'] ?? 0,
      unitId: json['unitId'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SimpleCheckStockResult {
  final int productId;
  final int unitId;
  final bool isAvailable;
  final String message;

  SimpleCheckStockResult({
    required this.productId,
    required this.unitId,
    required this.isAvailable,
    required this.message,
  });

  factory SimpleCheckStockResult.fromJson(Map<String, dynamic> json) {
    return SimpleCheckStockResult(
      productId: json['productId'] ?? 0,
      unitId: json['unitId'] ?? 0,
      isAvailable: json['isEnough'] ?? json['isAvailable'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
