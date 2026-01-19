import 'package:json_annotation/json_annotation.dart';

// Dòng này báo cho build_runner biết tên file sinh ra sẽ là dashboard_stats.g.dart
part 'dashboard_stats.g.dart';

@JsonSerializable()
class DailyRevenue {
  final String dayName;
  final double amount;

  DailyRevenue(this.dayName, this.amount);

  // Kết nối với code sinh tự động
  factory DailyRevenue.fromJson(Map<String, dynamic> json) =>
      _$DailyRevenueFromJson(json);
  Map<String, dynamic> toJson() => _$DailyRevenueToJson(this);
}

@JsonSerializable()
class TopProduct {
  final int productId;
  // Backend OrderItems đang lưu UnitName, nhưng map vào productName
  final String productName;
  final double totalSold;
  final double totalRevenue;

  TopProduct(
    this.productId,
    this.productName,
    this.totalSold,
    this.totalRevenue,
  );

  factory TopProduct.fromJson(Map<String, dynamic> json) =>
      _$TopProductFromJson(json);
  Map<String, dynamic> toJson() => _$TopProductToJson(this);
}

@JsonSerializable()
class DashboardStats {
  final double todayRevenue;
  final int todayOrders;
  final double totalDebt;
  final List<DailyRevenue> weeklyRevenue;
  final List<TopProduct> topProducts;

  DashboardStats({
    required this.todayRevenue,
    required this.todayOrders,
    required this.totalDebt,
    required this.weeklyRevenue,
    required this.topProducts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}
