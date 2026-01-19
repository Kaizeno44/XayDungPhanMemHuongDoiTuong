import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../core/config/api_config.dart'; // Import file config chứa URL

class ReportService {
  Future<DashboardStats> getOwnerDashboardStats() async {
    try {
      final uri = Uri.parse('${ApiConfig.orderBaseUrl}/api/Dashboard/stats');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return DashboardStats(
          todayRevenue: (data['todayRevenue'] as num).toDouble(),
          todayOrders: (data['todayOrders'] ?? 0) as int, // Map số đơn
          totalDebt: (data['totalDebt'] as num).toDouble(),

          weeklyRevenue: (data['weeklyRevenue'] as List).map((item) {
            return DailyRevenue(
              item['dayName'],
              (item['amount'] as num).toDouble(),
            );
          }).toList(),

          // Map Top sản phẩm
          topProducts: (data['topProducts'] as List? ?? []).map((item) {
            return TopProduct(
              item['productId'] ?? 0,
              item['productName'] ??
                  'Sản phẩm #${item['productId']}', // Tạm thời
              (item['totalSold'] as num).toDouble(),
              (item['totalRevenue'] as num).toDouble(),
            );
          }).toList(),
        );
      } else {
        throw Exception("Lỗi API");
      }
    } catch (e) {
      // Return default empty data
      return DashboardStats(
        todayRevenue: 0,
        todayOrders: 0,
        totalDebt: 0,
        weeklyRevenue: [],
        topProducts: [],
      );
    }
  }
}
