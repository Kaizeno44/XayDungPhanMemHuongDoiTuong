class DashboardStats {
  final double todayRevenue;
  final int todayOrdersCount;
  final double totalDebt;
  final List<DailyRevenue> weeklyRevenue;
  final List<TopProduct> topProducts;

  DashboardStats({
    required this.todayRevenue,
    required this.todayOrdersCount,
    required this.totalDebt,
    required this.weeklyRevenue,
    required this.topProducts,
  });

  // 1. Factory rỗng
  factory DashboardStats.empty() {
    return DashboardStats(
      todayRevenue: 0,
      todayOrdersCount: 0,
      totalDebt: 0,
      weeklyRevenue: [],
      topProducts: [],
    );
  }

  // 2. Factory từ JSON (FIX LỖI SUBTYPE TẠI ĐÂY)
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayRevenue: _parseSafeDouble(
        json['todayRevenue'] ?? json['TodayRevenue'],
      ),

      todayOrdersCount: _parseSafeInt(
        json['todayOrdersCount'] ??
            json['TodayOrdersCount'] ??
            json['todayOrders'],
      ),

      totalDebt: _parseSafeDouble(json['totalDebt'] ?? json['TotalDebt']),

      // [FIX QUAN TRỌNG] Sử dụng List<T>.from(...)
      // Thay vì .toList(), ta dùng List.from để ép kiểu danh sách tường minh
      weeklyRevenue: List<DailyRevenue>.from(
        (json['weeklyRevenue'] ?? json['WeeklyRevenue'] as List? ?? []).map(
          (x) => DailyRevenue.fromJson(x),
        ),
      ),

      // [FIX QUAN TRỌNG] Tương tự với TopProducts
      topProducts: List<TopProduct>.from(
        (json['topProducts'] ?? json['TopProducts'] as List? ?? []).map(
          (x) => TopProduct.fromJson(x),
        ),
      ),
    );
  }
}

// --- CLASS CON ---

class DailyRevenue {
  final String dayName;
  final double amount;

  DailyRevenue(this.dayName, this.amount);

  // [NÂNG CẤP] Nhận dynamic thay vì Map để tránh lỗi cast
  factory DailyRevenue.fromJson(dynamic json) {
    if (json == null || json is! Map) return DailyRevenue('', 0);

    return DailyRevenue(
      json['dayName'] ?? json['DayName'] ?? '',
      _parseSafeDouble(json['amount'] ?? json['Amount']),
    );
  }
}

class TopProduct {
  final int productId;
  final String productName;
  final double totalSold;
  final double totalRevenue;

  TopProduct(
    this.productId,
    this.productName,
    this.totalSold,
    this.totalRevenue,
  );

  // [NÂNG CẤP] Nhận dynamic thay vì Map
  factory TopProduct.fromJson(dynamic json) {
    if (json == null || json is! Map) return TopProduct(0, 'Unknown', 0, 0);

    final pId = _parseSafeInt(json['productId'] ?? json['ProductId']);
    return TopProduct(
      pId,
      json['productName'] ?? json['ProductName'] ?? 'SP #$pId',
      _parseSafeDouble(
        json['totalQuantity'] ?? json['TotalQuantity'] ?? json['totalSold'],
      ),
      _parseSafeDouble(json['totalRevenue'] ?? json['TotalRevenue']),
    );
  }
}

// --- CÁC HÀM PARSE AN TOÀN (PRIVATE) ---

double _parseSafeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseSafeInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
