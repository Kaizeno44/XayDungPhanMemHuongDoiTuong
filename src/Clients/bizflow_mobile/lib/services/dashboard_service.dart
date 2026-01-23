import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../core/config/api_config.dart';

class DashboardService {
  // 1. Hàm đọc số thực an toàn (Bất chấp null, string, int)
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

  Future<DashboardStats> getStats(String storeId) async {
    try {
      // Gọi API lấy thống kê
      final uri = Uri.parse('${ApiConfig.dashboardStats}?storeId=$storeId');
      print("📡 Calling Dashboard API: $uri");

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return DashboardStats(
          // Mapping an toàn từng trường
          todayRevenue: _parseSafeDouble(
            data['todayRevenue'] ?? data['TodayRevenue'],
          ),

          // Ưu tiên tìm 'todayOrdersCount' (từ backend)
          todayOrdersCount: _parseSafeInt(
            data['todayOrdersCount'] ??
                data['TodayOrdersCount'] ??
                data['todayOrders'],
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
              _parseSafeDouble(
                item['totalQuantity'] ??
                    item['TotalQuantity'] ??
                    item['totalSold'],
              ),
              _parseSafeDouble(item['totalRevenue'] ?? item['TotalRevenue']),
            );
          }).toList(),
        );
      } else {
        print("❌ Lỗi API Dashboard: ${response.statusCode} - ${response.body}");
        throw Exception("Lỗi API: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception Dashboard: $e");
      // Trả về dữ liệu rỗng để App không bị chết
      return DashboardStats(
        todayRevenue: 0,
        todayOrdersCount: 0,
        totalDebt: 0,
        weeklyRevenue: [],
        topProducts: [],
      );
    }
  }
}
