import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart'; // Import các model đã định nghĩa
import 'config/api_config.dart'; // Import ApiConfig

class ApiService {
  // Sử dụng các base URL từ ApiConfig
  static final String _productApiBaseUrl = ApiConfig.productBaseUrl;
  static final String _orderApiBaseUrl = ApiConfig.orderBaseUrl;

  Future<List<Product>> getProducts({String? keyword, int? categoryId, int page = 1, int pageSize = 10}) async {
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

    final uri = Uri.parse('$_productApiBaseUrl/api/Products').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> productJson = data['data'];
      return productJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode} ${response.body}');
    }
  }

  Future<ProductPriceResult> getProductPrice(int productId, int unitId) async {
    final uri = Uri.parse('$_productApiBaseUrl/api/Products/$productId/price?unitId=$unitId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return ProductPriceResult.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load product price: ${response.statusCode} ${response.body}');
    }
  }

  Future<SimpleCheckStockResult> simpleCheckStock(int productId, int unitId, double quantity) async {
    final uri = Uri.parse('$_productApiBaseUrl/api/Products/check-stock');
    final requestBody = {
      'requests': [
        {
          'productId': productId,
          'unitId': unitId,
          'quantity': quantity.toInt(), // Chuyển đổi quantity sang int
        }
      ]
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody), // Gửi đối tượng wrapper
    );

    if (response.statusCode == 200) {
      final dynamic decodedBody = json.decode(response.body);
      if (decodedBody is List && decodedBody.isNotEmpty) {
        // Nếu backend trả về một danh sách, lấy phần tử đầu tiên
        return SimpleCheckStockResult.fromJson(decodedBody.first as Map<String, dynamic>);
      } else if (decodedBody is Map<String, dynamic>) {
        // Nếu backend trả về một đối tượng duy nhất (trường hợp dự phòng)
        return SimpleCheckStockResult.fromJson(decodedBody);
      } else {
        throw Exception('Failed to check stock: Unexpected response format');
      }
    } else {
      throw Exception('Failed to check stock: ${response.statusCode} ${response.body}');
    }
  }
}
