import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats.g.dart';

@JsonSerializable()
class DailyRevenue {
  // Backend trả về: "dayName"
  final String dayName;

  // Backend trả về: "amount" (chữ thường)
  // SỬA: Đổi từ 'Amount' thành 'amount' hoặc bỏ luôn @JsonKey cũng được
  @JsonKey(name: 'amount')
  final double amount;

  DailyRevenue(this.dayName, this.amount);

  factory DailyRevenue.fromJson(Map<String, dynamic> json) =>
      _$DailyRevenueFromJson(json);
  Map<String, dynamic> toJson() => _$DailyRevenueToJson(this);
}

@JsonSerializable()
class TopProduct {
  final int productId;

  // Backend có thể không trả về productName nếu truy vấn LINQ chưa Include đúng,
  // nên cho phép null (String?) để an toàn.
  final String? productName;

  // Backend trả về: "totalQuantity"
  @JsonKey(name: 'totalQuantity')
  final double totalSold;

  // Backend trả về: "totalRevenue"
  @JsonKey(name: 'totalRevenue')
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
  // Backend trả về: "todayRevenue"
  final double todayRevenue;

  // Backend trả về: "todayOrdersCount"
  final int todayOrdersCount; // Sửa tên biến cho khớp luôn để đỡ dùng @JsonKey

  // Backend trả về: "totalDebt"
  final double totalDebt;

  // Backend trả về: "weeklyRevenue"
  final List<DailyRevenue> weeklyRevenue;

  // Backend trả về: "topProducts"
  final List<TopProduct> topProducts;

  DashboardStats({
    required this.todayRevenue,
    required this.todayOrdersCount,
    required this.totalDebt,
    required this.weeklyRevenue,
    required this.topProducts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}
