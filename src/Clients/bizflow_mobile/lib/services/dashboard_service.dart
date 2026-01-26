import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../core/config/api_config.dart';

class DashboardService {
  // 1. Hàm đọc số thực an toàn
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
      // --- BƯỚC 1: CHUẨN BỊ URL ---

      // URL API 1: Thống kê chính (Doanh thu, đơn hàng, biểu đồ)
      final statsUri = Uri.parse(
        '${ApiConfig.dashboardStats}?storeId=$storeId',
      );

      // URL API 2: Sản phẩm sắp hết hàng (Lấy từ Product API)
      // Lưu ý: Đảm bảo đường dẫn này đúng với Backend của bạn
      // Nếu ApiConfig chưa có baseUrl, hãy thay thế bằng chuỗi cứng hoặc thêm vào ApiConfig
      final lowStockUri = Uri.parse(
        '${ApiConfig.lowStock}?storeId=$storeId&threshold=10',
      );

      print("📡 [Dashboard] Fetching data...");
      print("   - Stats: $statsUri");
      print("   - LowStock: $lowStockUri");

      // --- BƯỚC 2: GỌI API SONG SONG (Tối ưu tốc độ) ---
      final responses = await Future.wait([
        http.get(statsUri, headers: ApiConfig.headers), // Index 0
        http.get(lowStockUri, headers: ApiConfig.headers), // Index 1
      ]);

      final statsResponse = responses[0];
      final lowStockResponse = responses[1];

      // --- BƯỚC 3: XỬ LÝ DỮ LIỆU THỐNG KÊ CHÍNH ---
      double todayRevenue = 0;
      int todayOrdersCount = 0;
      double totalDebt = 0;
      List<DailyRevenue> weeklyRevenue = [];
      List<TopProduct> topProducts = [];

      if (statsResponse.statusCode == 200) {
        final data = json.decode(statsResponse.body);

        todayRevenue = _parseSafeDouble(
          data['todayRevenue'] ?? data['TodayRevenue'],
        );

        todayOrdersCount = _parseSafeInt(
          data['todayOrdersCount'] ??
              data['TodayOrdersCount'] ??
              data['todayOrders'],
        );

        totalDebt = _parseSafeDouble(data['totalDebt'] ?? data['TotalDebt']);

        weeklyRevenue = (data['weeklyRevenue'] as List? ?? []).map((item) {
          return DailyRevenue(
            item['dayName'] ?? item['DayName'] ?? '',
            _parseSafeDouble(item['amount'] ?? item['Amount']),
          );
        }).toList();

        topProducts = (data['topProducts'] as List? ?? []).map((item) {
          return TopProduct(
            item['productId'] ?? 0,
            item['productName'], // Để null cho model tự xử lý hiển thị
            _parseSafeDouble(item['totalQuantity'] ?? item['totalSold']),
            _parseSafeDouble(item['totalRevenue']),
          );
        }).toList();
      } else {
        print(
          "❌ Lỗi API Stats: ${statsResponse.statusCode} - ${statsResponse.body}",
        );
      }

      // --- BƯỚC 4: XỬ LÝ DỮ LIỆU SẮP HẾT HÀNG ---
      List<LowStockItem> lowStockItems = [];

      if (lowStockResponse.statusCode == 200) {
        final dynamic decoded = json.decode(lowStockResponse.body);
        // Kiểm tra xem backend trả về List trực tiếp hay object chứa list
        final List<dynamic> listData = (decoded is List)
            ? decoded
            : (decoded['items'] ?? []);

        lowStockItems = listData.map((item) {
          return LowStockItem(
            id: item['id'] ?? item['productId'] ?? 0,
            name: item['name'] ?? item['productName'] ?? 'Sản phẩm lỗi tên',
            sku: item['sku'] ?? '',
            currentStock: _parseSafeDouble(
              item['currentStock'] ?? item['quantity'],
            ),
          );
        }).toList();
      } else {
        // Không throw lỗi ở đây để Dashboard vẫn hiện các thông tin khác
        print(
          "⚠️ Warning: Không lấy được Low Stock data (${lowStockResponse.statusCode})",
        );
      }

      // --- BƯỚC 5: TRẢ VỀ KẾT QUẢ TỔNG HỢP ---
      return DashboardStats(
        todayRevenue: todayRevenue,
        todayOrdersCount: todayOrdersCount,
        totalDebt: totalDebt,
        weeklyRevenue: weeklyRevenue,
        topProducts: topProducts,
        lowStockItems: lowStockItems,
      );
    } catch (e) {
      print("⚠️ Exception DashboardService: $e");
      // Trả về dữ liệu rỗng an toàn để App không bị Crash màn hình trắng
      return DashboardStats(
        todayRevenue: 0,
        todayOrdersCount: 0,
        totalDebt: 0,
        weeklyRevenue: [],
        topProducts: [],
        lowStockItems: [],
      );
    }
  }
}
