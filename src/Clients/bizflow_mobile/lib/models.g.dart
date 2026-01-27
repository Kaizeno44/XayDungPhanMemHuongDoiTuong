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

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
      id: _readIdAsString(json, 'id') as String,
      orderCode: json['orderCode'] as String? ?? '',
      orderDate: _parseDate(json['orderDate']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
    );

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
      'id': instance.id,
      'orderCode': instance.orderCode,
      'orderDate': instance.orderDate.toIso8601String(),
      'totalAmount': instance.totalAmount,
      'status': instance.status,
      'paymentMethod': instance.paymentMethod,
    };

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
      id: _readIdAsString(json, 'id') as String,
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

DebtLog _$DebtLogFromJson(Map<String, dynamic> json) => DebtLog(
      id: _readIdAsString(json, 'id') as String,
      amount: (json['amount'] as num).toDouble(),
      action: json['action'] as String? ?? 'Debit',
      reason: json['reason'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );

Map<String, dynamic> _$DebtLogToJson(DebtLog instance) => <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'action': instance.action,
      'reason': instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
    };

CashBookItem _$CashBookItemFromJson(Map<String, dynamic> json) => CashBookItem(
      id: _readIdAsString(json, 'id') as String,
      customerId: _readIdAsString(json, 'customerId') as String,
      customerName: json['customerName'] as String? ?? 'Khách lẻ',
      amount: (json['amount'] as num).toDouble(),
      action: json['action'] as String? ?? '',
      type: json['type'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );

Map<String, dynamic> _$CashBookItemToJson(CashBookItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'amount': instance.amount,
      'action': instance.action,
      'type': instance.type,
      'reason': instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
    };

RevenueStat _$RevenueStatFromJson(Map<String, dynamic> json) => RevenueStat(
      date: json['date'] as String,
      revenue: (json['revenue'] as num).toDouble(),
    );

Map<String, dynamic> _$RevenueStatToJson(RevenueStat instance) =>
    <String, dynamic>{
      'date': instance.date,
      'revenue': instance.revenue,
    };

ProductPriceResult _$ProductPriceResultFromJson(Map<String, dynamic> json) =>
    ProductPriceResult(
      productId: (json['productId'] as num).toInt(),
      unitId: (json['unitId'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$ProductPriceResultToJson(ProductPriceResult instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'unitId': instance.unitId,
      'price': instance.price,
    };

SimpleCheckStockResult _$SimpleCheckStockResultFromJson(
        Map<String, dynamic> json) =>
    SimpleCheckStockResult(
      productId: (json['productId'] as num).toInt(),
      unitId: (json['unitId'] as num).toInt(),
      isAvailable:
          SimpleCheckStockResult._readIsAvailable(json, 'isAvailable') as bool,
      message: json['message'] as String? ?? '',
    );

Map<String, dynamic> _$SimpleCheckStockResultToJson(
        SimpleCheckStockResult instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'unitId': instance.unitId,
      'isAvailable': instance.isAvailable,
      'message': instance.message,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: _readIdAsString(json, 'id') as String,
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
          AuthResponse._readUser(json, 'user') as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'user': instance.user,
    };
