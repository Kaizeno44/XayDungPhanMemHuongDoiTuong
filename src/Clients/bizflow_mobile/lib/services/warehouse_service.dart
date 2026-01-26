import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/stock_import.dart';

class WarehouseService {
  // ==========================================
  // 1. LẤY LỊCH SỬ NHẬP KHO
  // ==========================================
  Future<List<StockImport>> getImportHistory(
    String storeId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      // Xây dựng URL với tham số phân trang
      final uri = Uri.parse(
        '${ApiConfig.stockImports}?storeId=$storeId&page=$page&pageSize=$pageSize',
      );
      print("📦 [GET] Lịch sử nhập kho: $uri");

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> listRaw = [];

        // Xử lý linh hoạt các format trả về của API (List hoặc Paging Object)
        if (decodedData is List) {
          listRaw = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData['data'] != null) {
            listRaw = decodedData['data'];
          } else if (decodedData['items'] != null) {
            listRaw = decodedData['items'];
          } else if (decodedData['results'] != null) {
            listRaw = decodedData['results'];
          }
        }

        // Map sang Model an toàn (bỏ qua phần tử lỗi)
        return listRaw
            .map((e) {
              try {
                return StockImport.fromJson(e);
              } catch (err) {
                print("⚠️ Lỗi map item nhập kho: $err");
                return null;
              }
            })
            .whereType<StockImport>()
            .toList();
      } else {
        print("❌ Lỗi API Lịch sử (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      print("⚠️ Exception Lịch sử Kho: $e");
      return [];
    }
  }

  // ==========================================
  // 2. TẠO PHIẾU NHẬP KHO MỚI
  // ==========================================
  Future<bool> createImport({
    required String storeId,
    required List<Map<String, dynamic>> details, // Danh sách chi tiết
    String? notes,
  }) async {
    try {
      // [SỬA LỖI QUAN TRỌNG TẠI ĐÂY]
      // Thêm query param storeId vào URL để Backend định tuyến đúng Tenant (Database)
      final uri = Uri.parse('${ApiConfig.stockImports}?storeId=$storeId');

      print("📦 [POST] Tạo phiếu nhập: $uri");

      // Chuẩn bị dữ liệu gửi đi (Payload)
      final payload = {
        "storeId": storeId,
        "notes": notes ?? "Nhập hàng qua Mobile App",
        "details": details,
      };

      final body = json.encode(payload);

      // --- DEBUG LOG ---
      print("📦 Body gửi đi (Payload): $body");
      // -----------------

      // Đảm bảo Header có Content-Type là JSON
      final headers = {
        ...ApiConfig.headers,
        "Content-Type": "application/json",
      };

      final response = await http.post(uri, headers: headers, body: body);

      // Chấp nhận 200 (OK) hoặc 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Tạo phiếu nhập thành công!");
        return true;
      } else {
        print("❌ Thất bại (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Exception tạo phiếu nhập: $e");
      return false;
    }
  }
}
