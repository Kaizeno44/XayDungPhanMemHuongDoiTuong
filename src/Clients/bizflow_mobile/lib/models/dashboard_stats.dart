class DailyRevenue {
  final String dayName;
  final double amount;
  DailyRevenue(this.dayName, this.amount);
}

// Class mới cho Top sản phẩm
class TopProduct {
  final int productId;
  final String
  productName; // Ở Backend OrderItems đang lưu UnitName, bạn có thể chỉnh lại backend để join bảng
  final double totalSold;
  final double totalRevenue;

  TopProduct(
    this.productId,
    this.productName,
    this.totalSold,
    this.totalRevenue,
  );
}

class DashboardStats {
  final double todayRevenue;
  final int todayOrders; // Mới
  final double totalDebt;
  final List<DailyRevenue> weeklyRevenue;
  final List<TopProduct> topProducts; // Mới

  DashboardStats({
    required this.todayRevenue,
    required this.todayOrders,
    required this.totalDebt,
    required this.weeklyRevenue,
    required this.topProducts,
  });
}
