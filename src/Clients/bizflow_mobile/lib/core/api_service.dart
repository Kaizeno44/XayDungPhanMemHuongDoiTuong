import 'dart:convert';
import 'package:flutter/foundation.dart'; // Để dùng kDebugMode
import 'package:http/http.dart' as http;
import '../models.dart'; // Import các model đã định nghĩa
import 'config/api_config.dart'; // Import ApiConfig

class ApiService {
  // Sử dụng các base URL từ ApiConfig cho Product và Order
  static final String _productApiBaseUrl = ApiConfig.productBaseUrl;
  static final String _orderApiBaseUrl = ApiConfig.orderBaseUrl;

  // [ĐÃ SỬA] Thay vì lấy từ Config, tôi điền trực tiếp IP Wifi của bạn vào đây
  // để đảm bảo App tìm thấy Server Identity ngay lập tức.
  // IP này lấy từ 'Wireless LAN adapter Wi-Fi' trong ipconfig của bạn.
  static const String _identityApiBaseUrl = 'http://10.0.2.2:5000';

  // ===========================================================================
  // 1. PRODUCT SERVICE METHODS
  // ===========================================================================

  Future<List<Product>> getProducts({
    String? keyword,
    int? categoryId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    if (categoryId != null && categoryId > 0) {
      queryParams['categoryId'] = categoryId.toString();
    }

    final uri = Uri.parse(
      '$_productApiBaseUrl/api/Products',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> productJson = data['data'];
      return productJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load products: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<ProductPriceResult> getProductPrice(int productId, int unitId) async {
    final uri = Uri.parse(
      '$_productApiBaseUrl/api/Products/$productId/price?unitId=$unitId',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return ProductPriceResult.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to load product price: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<SimpleCheckStockResult> simpleCheckStock(
    int productId,
    int unitId,
    double quantity,
  ) async {
    final uri = Uri.parse('$_productApiBaseUrl/api/Products/check-stock');
    final requestBody = {
      'requests': [
        {
          'productId': productId,
          'unitId': unitId,
          'quantity': quantity.toInt(),
        },
      ],
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final dynamic decodedBody = json.decode(response.body);
      if (decodedBody is List && decodedBody.isNotEmpty) {
        return SimpleCheckStockResult.fromJson(
          decodedBody.first as Map<String, dynamic>,
        );
      } else if (decodedBody is Map<String, dynamic>) {
        return SimpleCheckStockResult.fromJson(decodedBody);
      } else {
        throw Exception('Failed to check stock: Unexpected response format');
      }
    } else {
      throw Exception(
        'Failed to check stock: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ===========================================================================
  // 2. GENERIC POST METHOD (Đã cập nhật Router)
  // ===========================================================================

  /// Hàm Post dùng chung cho toàn bộ App
  /// Tự động định tuyến URL dựa trên endpoint truyền vào
  Future<void> post(
    String endpoint, {
    required Map<String, dynamic> data,
  }) async {
    String baseUrl;

    // Logic định tuyến (Router):
    // - Nếu gọi api liên quan user/auth -> Dùng Identity Server (IP 172.16.2.174)
    if (endpoint.startsWith('/api/users') || endpoint.contains('auth')) {
      baseUrl = _identityApiBaseUrl;
    }
    // - Nếu gọi đơn hàng/hóa đơn -> Dùng Order Server
    else if (endpoint.startsWith('/api/orders') ||
        endpoint.startsWith('/api/invoices')) {
      baseUrl = _orderApiBaseUrl;
    }
    // - Còn lại -> Dùng Product Server
    else {
      baseUrl = _productApiBaseUrl;
    }

    // Xây dựng URL đầy đủ
    final uri = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      print('🌐 POST Request: $uri');
      print('📦 Body: ${json.encode(data)}');
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type':
              'application/json', // Quan trọng: Để Backend hiểu JSON
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('✅ POST Success: ${response.statusCode}');
        }
        return; // Thành công
      } else {
        if (kDebugMode) {
          print('❌ POST Failed: ${response.statusCode} - ${response.body}');
        }
        // Ném lỗi để bên ngoài (UI/Provider) bắt được
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connection Error: $e');
      }
      rethrow; // Ném tiếp lỗi ra ngoài
    }
  }
}
