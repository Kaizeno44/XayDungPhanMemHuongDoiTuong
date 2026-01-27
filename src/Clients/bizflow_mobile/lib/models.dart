import 'package:json_annotation/json_annotation.dart';

export 'models/product.dart';

part 'models.g.dart';

// ============================================================================
//                               GLOBAL HELPERS
// ============================================================================

// Helper 1: Đọc ID an toàn (chấp nhận cả int, String, GUID)
Object? _readIdAsString(Map map, String key) {
  Object? value =
      map[key] ?? map['Id'] ?? map['ID'] ?? map['customerId'] ?? map['orderId'];
  return value?.toString() ?? '';
}

// [FIX] Helper 2: Parse ngày tháng thủ công để tránh lỗi ép kiểu
DateTime _parseDate(dynamic date) {
  if (date == null) return DateTime.now();
  if (date is DateTime) return date;
  if (date is String) {
    // Thử parse, nếu lỗi thì trả về hiện tại để không crash app
    return DateTime.tryParse(date)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}

// ============================================================================
//                               CART & ORDER
// ============================================================================

@JsonSerializable()
class CartItem {
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double price;
  int quantity;
  double maxStock;

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

// Model cho lịch sử đơn hàng
@JsonSerializable()
class Order {
  @JsonKey(readValue: _readIdAsString)
  final String id;

  @JsonKey(defaultValue: '')
  final String orderCode;

  // [FIX] Sử dụng fromJson để parse an toàn
  @JsonKey(fromJson: _parseDate)
  final DateTime orderDate;

  final double totalAmount;
  final String status;
  final String paymentMethod;

  Order({
    required this.id,
    required this.orderCode,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

// ============================================================================
//                               CUSTOMER & DEBT
// ============================================================================

@JsonSerializable()
class Customer {
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

  static Object? _readName(Map map, String key) {
    return map['fullName'] ?? map['name'] ?? map['customerName'] ?? 'Khách lẻ';
  }

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}

@JsonSerializable()
class DebtLog {
  @JsonKey(readValue: _readIdAsString)
  final String id;

  final double amount;

  @JsonKey(defaultValue: 'Debit')
  final String action;

  @JsonKey(defaultValue: '')
  final String reason;

  // [FIX] Sử dụng fromJson để parse an toàn
  @JsonKey(fromJson: _parseDate)
  final DateTime createdAt;

  DebtLog({
    required this.id,
    required this.amount,
    required this.action,
    required this.reason,
    required this.createdAt,
  });

  factory DebtLog.fromJson(Map<String, dynamic> json) =>
      _$DebtLogFromJson(json);
  Map<String, dynamic> toJson() => _$DebtLogToJson(this);
}

// ============================================================================
//                               ACCOUNTING / DASHBOARD
// ============================================================================

@JsonSerializable()
class CashBookItem {
  @JsonKey(readValue: _readIdAsString)
  final String id;

  @JsonKey(readValue: _readIdAsString)
  final String customerId;

  @JsonKey(defaultValue: 'Khách lẻ')
  final String customerName;

  final double amount;

  @JsonKey(defaultValue: '')
  final String action;

  @JsonKey(defaultValue: '')
  final String type;

  @JsonKey(defaultValue: '')
  final String reason;

  // [FIX] Sử dụng fromJson để parse an toàn
  @JsonKey(fromJson: _parseDate)
  final DateTime createdAt;

  CashBookItem({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.action,
    required this.type,
    required this.reason,
    required this.createdAt,
  });

  factory CashBookItem.fromJson(Map<String, dynamic> json) =>
      _$CashBookItemFromJson(json);
  Map<String, dynamic> toJson() => _$CashBookItemToJson(this);
}

@JsonSerializable()
class RevenueStat {
  final String date;
  final double revenue;

  RevenueStat({required this.date, required this.revenue});

  factory RevenueStat.fromJson(Map<String, dynamic> json) =>
      _$RevenueStatFromJson(json);
  Map<String, dynamic> toJson() => _$RevenueStatToJson(this);
}

// ============================================================================
//                               STOCK & AUTH
// ============================================================================

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

@JsonSerializable()
class User {
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

  static Object? _readCaseInsensitive(Map map, String key) {
    if (map.containsKey(key)) return map[key]?.toString() ?? '';
    if (key.isNotEmpty) {
      String capitalized = key[0].toUpperCase() + key.substring(1);
      return map[capitalized]?.toString() ?? '';
    }
    return '';
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
