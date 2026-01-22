import 'package:json_annotation/json_annotation.dart';

// 1. Export file Product để các file khác chỉ cần import models.dart là đủ
export 'models/product.dart';
// export 'models/dashboard_stats.dart'; // Bỏ comment nếu có file này

part 'models.g.dart';

// ================= CART ITEM (Giỏ hàng) =================
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

  // [CẢI TIẾN] Thêm copyWith để dễ dàng update số lượng trong Riverpod
  CartItem copyWith({
    int? productId,
    String? productName,
    int? unitId,
    String? unitName,
    double? price,
    int? quantity,
    double? maxStock,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);
}

// ================= CUSTOMER (Khách hàng) =================
@JsonSerializable()
class Customer {
  // Dùng helper để đọc ID an toàn (chấp nhận cả int lẫn String từ server)
  @JsonKey(readValue: _readIdAsString)
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

  // Helper: Đọc tên từ nhiều trường khác nhau (fallback)
  static Object? _readName(Map map, String key) {
    return map['fullName'] ?? map['name'] ?? map['customerName'] ?? 'Khách lẻ';
  }

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}

// ================= HELPER CLASSES (Check kho & Giá) =================
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

// ================= AUTH MODELS (User & Token) =================
@JsonSerializable()
class User {
  // [QUAN TRỌNG] Server Identity trả về GUID (String), không phải int
  // Helper này đảm bảo luôn convert sang String an toàn.
  @JsonKey(readValue: _readIdAsString)
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

  // Helper đọc key không phân biệt hoa thường (Id vs id) và xử lý null
  static Object? _readCaseInsensitive(Map map, String key) {
    if (map.containsKey(key)) return map[key]?.toString() ?? '';
    // Thử key viết hoa chữ cái đầu (VD: email -> Email)
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

// ================= GLOBAL HELPERS =================

// Hàm helper "thần thánh" để fix lỗi crash String/int
// Dùng cho User.id và Customer.id
Object? _readIdAsString(Map map, String key) {
  // 1. Thử tìm key chính xác (ví dụ "id")
  Object? value = map[key];

  // 2. Nếu không có, thử tìm key viết hoa ("Id", "ID")
  if (value == null) {
    value = map['Id'] ?? map['ID'];
  }

  // 3. Convert sang String an toàn
  return value?.toString() ?? '';
}
