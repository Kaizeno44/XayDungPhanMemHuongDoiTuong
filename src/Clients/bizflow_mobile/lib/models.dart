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
      name: json['fullName'] ?? json['name'] ?? 'Khách hàng',
    );
  }
}

// ================= PRODUCT =================
class Product {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<ProductUnit> productUnits;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.productUnits,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var unitsJson = json['productUnits'] as List;
    List<ProductUnit> units = unitsJson
        .map((e) => ProductUnit.fromJson(e))
        .toList();

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      productUnits: units,
    );
  }

  int? get unitId => null;

  get unitName => null;

  double get price => null;
}

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
      id: json['id'],
      unitName: json['unitName'],
      price: (json['price'] as num).toDouble(),
      isBaseUnit: json['isBaseUnit'],
    );
  }
}

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
      isEnough: json['isEnough'],
      message: json['message'],
    );
  }
}
