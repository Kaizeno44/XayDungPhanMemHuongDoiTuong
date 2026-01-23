// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyRevenue _$DailyRevenueFromJson(Map<String, dynamic> json) => DailyRevenue(
      json['dayName'] as String,
      (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$DailyRevenueToJson(DailyRevenue instance) =>
    <String, dynamic>{
      'dayName': instance.dayName,
      'amount': instance.amount,
    };

TopProduct _$TopProductFromJson(Map<String, dynamic> json) => TopProduct(
      (json['productId'] as num).toInt(),
      json['productName'] as String?,
      (json['totalQuantity'] as num).toDouble(),
      (json['totalRevenue'] as num).toDouble(),
    );

Map<String, dynamic> _$TopProductToJson(TopProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'totalQuantity': instance.totalSold,
      'totalRevenue': instance.totalRevenue,
    };

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      todayRevenue: (json['todayRevenue'] as num).toDouble(),
      todayOrdersCount: (json['todayOrdersCount'] as num).toInt(),
      totalDebt: (json['totalDebt'] as num).toDouble(),
      weeklyRevenue: (json['weeklyRevenue'] as List<dynamic>)
          .map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: (json['topProducts'] as List<dynamic>)
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardStatsToJson(DashboardStats instance) =>
    <String, dynamic>{
      'todayRevenue': instance.todayRevenue,
      'todayOrdersCount': instance.todayOrdersCount,
      'totalDebt': instance.totalDebt,
      'weeklyRevenue': instance.weeklyRevenue,
      'topProducts': instance.topProducts,
    };
