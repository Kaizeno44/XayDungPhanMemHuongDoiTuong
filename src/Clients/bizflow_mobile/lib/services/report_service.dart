import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../core/config/api_config.dart';

class ReportService {
  // 1. Hàm đọc số thực an toàn (Chống lỗi null/string)
  double _parseSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // 2. Hàm đọc số nguyên an toàn
  int _parseSafeInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<DashboardStats> getOwnerDashboardStats() async {
    try {
      final uri = Uri.parse(ApiConfig.dashboardStats);
      print("📡 Calling Dashboard API: $uri");

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return DashboardStats(
          // Map dữ liệu an toàn
          todayRevenue: _parseSafeDouble(
            data['todayRevenue'] ?? data['TodayRevenue'],
          ),

          // [SỬA LỖI TẠI ĐÂY]: Đổi 'todayOrders' thành 'todayOrdersCount'
          // Backend trả về: TodayOrdersCount
          todayOrdersCount: _parseSafeInt(
            data['todayOrdersCount'] ?? data['TodayOrdersCount'],
          ),

          totalDebt: _parseSafeDouble(data['totalDebt'] ?? data['TotalDebt']),

          // Xử lý mảng WeeklyRevenue
          weeklyRevenue: (data['weeklyRevenue'] as List? ?? []).map((item) {
            return DailyRevenue(
              item['dayName'] ?? item['DayName'] ?? '',
              _parseSafeDouble(item['amount'] ?? item['Amount']),
            );
          }).toList(),

          // Xử lý mảng TopProducts
          topProducts: (data['topProducts'] as List? ?? []).map((item) {
            return TopProduct(
              item['productId'] ?? 0,
              item['productName'] ?? 'Sản phẩm #${item['productId']}',
              // Backend trả về TotalQuantity, ưu tiên lấy nó
              _parseSafeDouble(
                item['totalQuantity'] ??
                    item['TotalQuantity'] ??
                    item['totalSold'],
              ),
              _parseSafeDouble(item['totalRevenue'] ?? item['TotalRevenue']),
            );
          }).toList(),
          lowStockItems: [],
        );
      } else {
        print("❌ Lỗi API Dashboard: ${response.statusCode} - ${response.body}");
        throw Exception("Lỗi API: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception Dashboard: $e");
      // Trả về dữ liệu rỗng để không crash app
      return DashboardStats(
        todayRevenue: 0,
        // [SỬA LỖI TẠI ĐÂY CẢ TRONG CATCH]
        todayOrdersCount: 0,
        totalDebt: 0,
        weeklyRevenue: [],
        topProducts: [],
        lowStockItems: [],
      );
    }
  }
}
