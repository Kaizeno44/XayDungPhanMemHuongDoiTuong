// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyRevenue _$DailyRevenueFromJson(Map<String, dynamic> json) => DailyRevenue(
      json['dayName'] as String? ?? '',
      (json['amount'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$DailyRevenueToJson(DailyRevenue instance) =>
    <String, dynamic>{
      'dayName': instance.dayName,
      'amount': instance.amount,
    };

TopProduct _$TopProductFromJson(Map<String, dynamic> json) => TopProduct(
      (json['productId'] as num?)?.toInt() ?? 0,
      json['productName'] as String?,
      (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$TopProductToJson(TopProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'totalQuantity': instance.totalSold,
      'totalRevenue': instance.totalRevenue,
    };

LowStockItem _$LowStockItemFromJson(Map<String, dynamic> json) => LowStockItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Sản phẩm chưa đặt tên',
      sku: json['sku'] as String? ?? '',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$LowStockItemToJson(LowStockItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'currentStock': instance.currentStock,
    };

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      todayOrdersCount: (json['todayOrdersCount'] as num?)?.toInt() ?? 0,
      totalDebt: (json['totalDebt'] as num?)?.toDouble() ?? 0.0,
      weeklyRevenue: (json['weeklyRevenue'] as List<dynamic>?)
              ?.map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topProducts: (json['topProducts'] as List<dynamic>?)
              ?.map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lowStockItems: (json['lowStockItems'] as List<dynamic>?)
              ?.map((e) => LowStockItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$DashboardStatsToJson(DashboardStats instance) =>
    <String, dynamic>{
      'todayRevenue': instance.todayRevenue,
      'todayOrdersCount': instance.todayOrdersCount,
      'totalDebt': instance.totalDebt,
      'weeklyRevenue': instance.weeklyRevenue,
      'topProducts': instance.topProducts,
      'lowStockItems': instance.lowStockItems,
    };
