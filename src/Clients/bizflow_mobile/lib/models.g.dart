// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  productId: (json['productId'] as num).toInt(),
  productName: json['productName'] as String,
  unitId: (json['unitId'] as num).toInt(),
  unitName: json['unitName'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  maxStock: (json['maxStock'] as num).toDouble(),
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'productName': instance.productName,
  'unitId': instance.unitId,
  'unitName': instance.unitName,
  'price': instance.price,
  'quantity': instance.quantity,
  'maxStock': instance.maxStock,
};

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  id: json['id'] as String,
  name: Customer._readName(json, 'name') as String,
  phone: json['phoneNumber'] as String? ?? '',
  address: json['address'] as String? ?? '',
  currentDebt: (json['currentDebt'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phoneNumber': instance.phone,
  'address': instance.address,
  'currentDebt': instance.currentDebt,
};

ProductPriceResult _$ProductPriceResultFromJson(Map<String, dynamic> json) =>
    ProductPriceResult(
      productId: (json['productId'] as num).toInt(),
      unitId: (json['unitId'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );

SimpleCheckStockResult _$SimpleCheckStockResultFromJson(
  Map<String, dynamic> json,
) => SimpleCheckStockResult(
  productId: (json['productId'] as num).toInt(),
  unitId: (json['unitId'] as num).toInt(),
  isAvailable:
      SimpleCheckStockResult._readIsAvailable(json, 'isAvailable') as bool,
  message: json['message'] as String? ?? '',
);

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: User._readCaseInsensitive(json, 'id') as String,
  email: User._readCaseInsensitive(json, 'email') as String,
  fullName: User._readCaseInsensitive(json, 'fullName') as String,
  role: User._readCaseInsensitive(json, 'role') as String,
  storeId: User._readCaseInsensitive(json, 'storeId') as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'role': instance.role,
  'storeId': instance.storeId,
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  token: AuthResponse._readToken(json, 'token') as String,
  user: User.fromJson(
    AuthResponse._readUser(json, 'user') as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{'token': instance.token, 'user': instance.user};
