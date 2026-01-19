import 'package:json_annotation/json_annotation.dart';

// 1. Export file Product mới tạo để các màn hình khác tìm thấy ProductUnit, Product
export 'models/product.dart';
// export 'models/dashboard_stats.dart'; // Bỏ comment nếu bạn đã tạo file này

part 'models.g.dart';

// ================= CART ITEM =================
@JsonSerializable()
class CartItem {
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double price;
  int quantity;
  final double maxStock;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.price,
    this.quantity = 1,
    required this.maxStock,
  });

  double get total => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);
}

// ================= CUSTOMER =================
@JsonSerializable()
class Customer {
  final String id;

  @JsonKey(readValue: _readName)
  final String name;

  @JsonKey(name: 'phoneNumber', defaultValue: '')
  final String phone;

  @JsonKey(defaultValue: '')
  final String address;

  @JsonKey(defaultValue: 0.0)
  double currentDebt;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.currentDebt = 0.0,
  });

  static Object? _readName(Map map, String key) {
    return map['fullName'] ?? map['name'] ?? 'Khách lẻ';
  }

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}

// ================= HELPER CLASSES =================
@JsonSerializable()
class ProductPriceResult {
  final int productId;
  final int unitId;
  final double price;

  ProductPriceResult({
    required this.productId,
    required this.unitId,
    required this.price,
  });

  factory ProductPriceResult.fromJson(Map<String, dynamic> json) =>
      _$ProductPriceResultFromJson(json);
}

@JsonSerializable()
class SimpleCheckStockResult {
  final int productId;
  final int unitId;

  @JsonKey(readValue: _readIsAvailable)
  final bool isAvailable;

  @JsonKey(defaultValue: '')
  final String message;

  SimpleCheckStockResult({
    required this.productId,
    required this.unitId,
    required this.isAvailable,
    required this.message,
  });

  static Object? _readIsAvailable(Map map, String key) {
    return map['isEnough'] ?? map['isAvailable'] ?? false;
  }

  factory SimpleCheckStockResult.fromJson(Map<String, dynamic> json) =>
      _$SimpleCheckStockResultFromJson(json);
}

// ================= AUTH MODELS =================
@JsonSerializable()
class User {
  @JsonKey(readValue: _readCaseInsensitive)
  final String id;

  @JsonKey(readValue: _readCaseInsensitive)
  final String email;

  @JsonKey(readValue: _readCaseInsensitive)
  final String fullName;

  @JsonKey(readValue: _readCaseInsensitive)
  final String role;

  @JsonKey(readValue: _readCaseInsensitive)
  final String storeId;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.storeId,
  });

  // Helper đọc key không phân biệt hoa thường (Id vs id)
  static Object? _readCaseInsensitive(Map map, String key) {
    // Thử key thường
    if (map.containsKey(key)) return map[key]?.toString() ?? '';
    // Thử key viết hoa chữ cái đầu
    String capitalized = key[0].toUpperCase() + key.substring(1);
    return map[capitalized]?.toString() ?? '';
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class AuthResponse {
  @JsonKey(readValue: _readToken)
  final String token;

  @JsonKey(readValue: _readUser)
  final User user;

  AuthResponse({required this.token, required this.user});

  static Object? _readToken(Map m, String k) => m['token'] ?? m['Token'] ?? '';
  static Object? _readUser(Map m, String k) => m['user'] ?? m['User'] ?? {};

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
