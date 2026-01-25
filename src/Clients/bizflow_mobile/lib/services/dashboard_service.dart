import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../core/config/api_config.dart';

class DashboardService {
  Future<DashboardStats> getStats(String storeId) async {
    try {
      final uri = Uri.parse('${ApiConfig.dashboardStats}?storeId=$storeId');
      // print("📡 Calling Dashboard API: $uri");

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Gọi hàm fromJson đã sửa lỗi
        return DashboardStats.fromJson(data);
      } else {
        print("❌ Lỗi API Dashboard: ${response.statusCode}");
        throw Exception("Lỗi API: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Exception Dashboard: $e");
      // Trả về object rỗng
      return DashboardStats.empty();
    }
  }
}
