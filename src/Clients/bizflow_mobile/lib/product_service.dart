import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart'; // Import Hive
import 'core/config/api_config.dart'; // Import config mới
import 'models.dart';

class ProductService {
  final String _productCacheBox = 'productCache';

  /// Lấy danh sách toàn bộ sản phẩm
  Future<List<Product>> getProducts() async {
    final url = Uri.parse(ApiConfig.products);
    List<Product> products = [];

    try {
      print('🔵 [ProductService] Đang gọi API: $url');
      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 10));

      print('🟢 [ProductService] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> listData = [];

        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
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

        products = listData.map((json) => Product.fromJson(json)).toList();

        // Lưu vào cache
        var box = await Hive.openBox(_productCacheBox);
        await box.put('products', jsonEncode(listData)); // Lưu raw JSON list
        print('✅ [ProductService] Đã lưu sản phẩm vào cache.');

        return products;
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } on SocketException {
      print('🔴 [ProductService] Không có kết nối mạng. Đang tải từ cache...');
      var box = await Hive.openBox(_productCacheBox);
      String? cachedData = box.get('products');
      if (cachedData != null) {
        print('✅ [ProductService] Đã tải sản phẩm từ cache.');
        List<dynamic> listData = jsonDecode(cachedData);
        return listData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Không có kết nối mạng và không có dữ liệu trong cache.');
      }
    } on TimeoutException {
      print('🔴 [ProductService] Kết nối quá hạn. Đang tải từ cache...');
      var box = await Hive.openBox(_productCacheBox);
      String? cachedData = box.get('products');
      if (cachedData != null) {
        print('✅ [ProductService] Đã tải sản phẩm từ cache.');
        List<dynamic> listData = jsonDecode(cachedData);
        return listData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Kết nối quá hạn và không có dữ liệu trong cache.');
      }
    } catch (e) {
      print('🔴 [ProductService] Lỗi chi tiết: $e');
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
