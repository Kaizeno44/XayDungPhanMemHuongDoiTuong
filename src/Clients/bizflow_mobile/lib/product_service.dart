import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'core/config/api_config.dart';
import 'models.dart';

class ProductService {
  final String _productCacheBox = 'productCache';

  /// Lấy danh sách sản phẩm (Hỗ trợ tìm kiếm)
  Future<List<Product>> getProducts({String? keyword}) async {
    // 1. Xây dựng URL có chứa tham số tìm kiếm
    Uri url = Uri.parse(ApiConfig.products);

    if (keyword != null && keyword.isNotEmpty) {
      // Nếu có keyword, thêm vào query params (ví dụ: ?keyword=xi mang)
      final newQueryParams = Map<String, String>.from(url.queryParameters);
      newQueryParams['keyword'] = keyword;
      url = url.replace(queryParameters: newQueryParams);
    }

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

        // Xử lý các định dạng trả về khác nhau của API
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
          }
        }

        products = listData.map((json) => Product.fromJson(json)).toList();

        // 👇 LOGIC CACHE: Chỉ lưu cache khi không tìm kiếm (tải toàn bộ)
        if (keyword == null || keyword.isEmpty) {
          var box = await Hive.openBox(_productCacheBox);
          await box.put('products', jsonEncode(listData));
          print('✅ [ProductService] Đã lưu danh sách gốc vào cache.');
        }

        return products;
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } on SocketException {
      // Chỉ tải cache khi không có mạng VÀ đang không tìm kiếm
      if (keyword != null && keyword.isNotEmpty) {
        throw Exception('Không có kết nối mạng để tìm kiếm.');
      }

      print('🔴 [ProductService] Không có kết nối mạng. Đang tải từ cache...');
      var box = await Hive.openBox(_productCacheBox);
      String? cachedData = box.get('products');
      if (cachedData != null) {
        print('✅ [ProductService] Đã tải sản phẩm từ cache.');
        List<dynamic> listData = jsonDecode(cachedData);
        return listData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Không có mạng và không có dữ liệu offline.');
      }
    } on TimeoutException {
      if (keyword != null && keyword.isNotEmpty) {
        throw Exception('Kết nối quá hạn khi tìm kiếm.');
      }

      print('🔴 [ProductService] Kết nối quá hạn. Đang tải từ cache...');
      var box = await Hive.openBox(_productCacheBox);
      String? cachedData = box.get('products');
      if (cachedData != null) {
        List<dynamic> listData = jsonDecode(cachedData);
        return listData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Kết nối quá hạn và không có dữ liệu cache.');
      }
    } catch (e) {
      print('🔴 [ProductService] Lỗi chi tiết: $e');
      throw Exception('Lỗi xử lý dữ liệu: $e');
    }
  }

  /// Lấy chi tiết 1 sản phẩm
  Future<Product> getProductById(int id) async {
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

  // ===========================================================================
  // 👇 HÀM MỚI: NHẬP KHO (STOCK IMPORT)
  // ===========================================================================
  Future<bool> importStock(
    List<Map<String, dynamic>> items,
    String note,
  ) async {
    // URL API nhập kho (Lưu ý: dùng productBaseUrl vì API này nằm bên ProductAPI)
    final url = Uri.parse('${ApiConfig.productBaseUrl}/api/Stock/import');

    final body = {
      "userId": 1, // Tạm thời hardcode userId, sau này lấy từ AuthProvider
      "note": note,
      "items": items,
    };

    try {
      print("🔵 [ProductService] Đang gửi phiếu nhập kho: $body");

      final response = await http
          .post(url, headers: ApiConfig.headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30)); // Timeout 30s cho chắc ăn

      print("🟢 [ProductService] Kết quả nhập kho: ${response.statusCode}");

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          "Lỗi server (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      print("🔴 [ProductService] Lỗi nhập kho: $e");
      throw Exception("Không thể nhập kho: $e");
    }
  }
}
