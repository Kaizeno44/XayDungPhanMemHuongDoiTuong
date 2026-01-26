import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats.g.dart';

// ==========================================
// 1. DOANH THU THEO NGÀY
// ==========================================
@JsonSerializable()
class DailyRevenue {
  // Backend: "dayName" (Ví dụ: "T2", "12/05")
  @JsonKey(defaultValue: "")
  final String dayName;

  // Backend: "amount"
  @JsonKey(name: 'amount', defaultValue: 0.0)
  final double amount;

  DailyRevenue(this.dayName, this.amount);

  factory DailyRevenue.fromJson(Map<String, dynamic> json) =>
      _$DailyRevenueFromJson(json);
  Map<String, dynamic> toJson() => _$DailyRevenueToJson(this);
}

// ==========================================
// 2. SẢN PHẨM BÁN CHẠY (TOP 5)
// ==========================================
@JsonSerializable()
class TopProduct {
  @JsonKey(defaultValue: 0)
  final int productId;

  // Cho phép null, nếu null thì UI tự hiển thị "Sản phẩm #ID"
  final String? productName;

  // Backend: "totalQuantity"
  @JsonKey(name: 'totalQuantity', defaultValue: 0.0)
  final double totalSold;

  // Backend: "totalRevenue"
  @JsonKey(name: 'totalRevenue', defaultValue: 0.0)
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

// ==========================================
// 3. SẢN PHẨM SẮP HẾT HÀNG (MỚI)
// ==========================================
@JsonSerializable()
class LowStockItem {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: "Sản phẩm chưa đặt tên")
  final String name;

  @JsonKey(defaultValue: "")
  final String sku;

  // Backend có thể trả về "currentStock" hoặc "quantity"
  // Bạn cần check kỹ backend trả key nào. Ở đây mình map theo "currentStock"
  @JsonKey(name: 'currentStock', defaultValue: 0.0)
  final double currentStock;

  LowStockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.currentStock,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) =>
      _$LowStockItemFromJson(json);
  Map<String, dynamic> toJson() => _$LowStockItemToJson(this);
}

// ==========================================
// 4. TỔNG HỢP DASHBOARD
// ==========================================
@JsonSerializable()
class DashboardStats {
  // Backend: "todayRevenue"
  @JsonKey(defaultValue: 0.0)
  final double todayRevenue;

  // Backend: "todayOrdersCount"
  @JsonKey(defaultValue: 0)
  final int todayOrdersCount;

  // Backend: "totalDebt"
  @JsonKey(defaultValue: 0.0)
  final double totalDebt;

  // Backend: "weeklyRevenue" - List doanh thu 7 ngày
  @JsonKey(defaultValue: [])
  final List<DailyRevenue> weeklyRevenue;

  // Backend: "topProducts" - List Top 5
  @JsonKey(defaultValue: [])
  final List<TopProduct> topProducts;

  // [MỚI] Backend: "lowStockItems" (Hoặc tên key bạn tự quy định khi gọi API song song)
  // Đây là danh sách sản phẩm sắp hết hàng
  @JsonKey(defaultValue: [])
  final List<LowStockItem> lowStockItems;

  DashboardStats({
    required this.todayRevenue,
    required this.todayOrdersCount,
    required this.totalDebt,
    required this.weeklyRevenue,
    required this.topProducts,
    required this.lowStockItems, // Nhớ required dòng này
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}
