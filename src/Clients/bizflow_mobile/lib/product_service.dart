import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'core/config/api_config.dart'; // Import config mới
import 'models.dart';

class ProductService {
  /// Lấy danh sách toàn bộ sản phẩm
  Future<List<Product>> getProducts() async {
    // SỬA LỖI: Dùng ApiConfig.products thay vì ghép chuỗi thủ công
    final url = Uri.parse(ApiConfig.products);

    try {
      print('🔵 [ProductService] Đang gọi API: $url');

      // Thêm timeout 10 giây để tránh treo app
      final response = await http
          .get(url, headers: ApiConfig.headers) // Dùng header chuẩn từ config
          .timeout(const Duration(seconds: 10));

      print('🟢 [ProductService] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 1. In ra body gốc để dễ debug nếu có lỗi
        // print('📄 [Body]: ${response.body}');

        // 2. Decode JSON sang kiểu dynamic
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> listData = [];

        // 3. Xử lý thông minh: Kiểm tra cấu trúc dữ liệu
        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          // Tìm key chứa danh sách (data, result, items...)
          if (decodedData.containsKey('data')) {
            listData = decodedData['data'];
          } else if (decodedData.containsKey('result')) {
            listData = decodedData['result'];
          } else if (decodedData.containsKey('items')) {
            listData = decodedData['items'];
          } else if (decodedData.containsKey('products')) {
            listData = decodedData['products'];
          } else {
            throw Exception(
              'API trả về Object nhưng không tìm thấy danh sách sản phẩm. Các key hiện có: ${decodedData.keys.toList()}',
            );
          }
        }

        // 4. Chuyển đổi từ JSON sang Model Product
        return listData.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw Exception('Lỗi 404: Không tìm thấy đường dẫn API.');
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'Không thể kết nối Server (Kiểm tra IP 10.0.2.2 và Port).',
      );
    } on TimeoutException {
      throw Exception('Kết nối quá hạn (Timeout). Server phản hồi quá lâu.');
    } catch (e) {
      print('🔴 Lỗi chi tiết: $e');
      throw Exception('Lỗi xử lý dữ liệu: $e');
    }
  }

  /// Lấy chi tiết 1 sản phẩm
  Future<Product> getProductById(int id) async {
    // SỬA LỖI: Dùng hàm helper trong ApiConfig
    final url = Uri.parse(ApiConfig.productDetail(id));

    try {
      final response = await http.get(url, headers: ApiConfig.headers);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return Product.fromJson(decoded['data']);
        }
        return Product.fromJson(decoded);
      } else {
        throw Exception('Không tìm thấy sản phẩm id: $id');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy chi tiết: $e');
    }
  }
}
