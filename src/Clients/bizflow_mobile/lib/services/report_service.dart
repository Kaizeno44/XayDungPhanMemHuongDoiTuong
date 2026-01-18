import '../models/dashboard_stats.dart';

class ReportService {
  Future<DashboardStats> getOwnerDashboardStats() async {
    // Giả lập delay mạng
    await Future.delayed(const Duration(seconds: 1));

    // Dữ liệu mẫu (Hardcode) - Sau này gọi API backend
    return DashboardStats(
      todayRevenue: 2500000, // 2.5 triệu
      totalDebt: 5400000, // 5.4 triệu (Số nợ cần báo động)
      weeklyRevenue: [
        DailyRevenue('T2', 1500000),
        DailyRevenue('T3', 2000000),
        DailyRevenue('T4', 1800000),
        DailyRevenue('T5', 2200000),
        DailyRevenue('T6', 2500000), // Hôm nay
        DailyRevenue('T7', 3000000),
        DailyRevenue('CN', 2800000),
      ],
    );
  }
}
