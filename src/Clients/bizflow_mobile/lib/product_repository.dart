import 'dart:convert';
import 'package:bizflow_mobile/product_service.dart';
// Để bắt lỗi của Chopper
import 'package:hive/hive.dart';

import '../models/product.dart';

class ProductRepository {
  final ProductService _productService;
  final String _productCacheBox = 'productCache';

  ProductRepository(this._productService);

  /// Helper: Xử lý dữ liệu trả về linh hoạt (giống logic cũ của bạn)
  List<Product> _parseProducts(dynamic responseBody) {
    List<dynamic> listData = [];

    if (responseBody is List) {
      listData = responseBody;
    } else if (responseBody is Map<String, dynamic>) {
      // Logic tìm key thông minh của bạn
      if (responseBody.containsKey('data')) {
        listData = responseBody['data'];
      } else if (responseBody.containsKey('result')) {
        listData = responseBody['result'];
      } else if (responseBody.containsKey('items')) {
        listData = responseBody['items'];
      } else if (responseBody.containsKey('products')) {
        listData = responseBody['products'];
      }
    }
    return listData.map((json) => Product.fromJson(json)).toList();
  }

  // =========================================================================
  // 1. GET PRODUCTS (Kèm Cache Hive)
  // =========================================================================
  Future<List<Product>> getProducts({String? keyword}) async {
    try {
      print('🔵 [Repo] Gọi API lấy sản phẩm...');

      // Gọi qua Chopper Service
      final response = await _productService.getProducts(keyword: keyword);

      if (response.isSuccessful) {
        final products = _parseProducts(response.body);

        // 👇 LOGIC CACHE: Chỉ lưu khi tải toàn bộ (không search)
        if (keyword == null || keyword.isEmpty) {
          var box = await Hive.openBox(_productCacheBox);
          // Lưu raw body cache để lần sau parse lại
          await box.put('products', jsonEncode(response.body));
          print('✅ [Repo] Đã lưu cache ${products.length} sản phẩm.');
        }

        return products;
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      // Logic Offline Mode
      bool isNetworkError =
          e is Exception; // Chopper ném Exception khi mất mạng

      if (isNetworkError) {
        // Chỉ tải cache khi KHÔNG tìm kiếm (hoặc tùy logic bạn muốn)
        if (keyword != null && keyword.isNotEmpty) {
          throw Exception('Không có mạng để tìm kiếm "$keyword"');
        }

        print('🔴 [Repo] Mất kết nối. Đang tải từ Cache Hive...');
        var box = await Hive.openBox(_productCacheBox);
        String? cachedData = box.get('products');

        if (cachedData != null) {
          final dynamic decoded = jsonDecode(cachedData);
          print('✅ [Repo] Khôi phục thành công từ cache.');
          return _parseProducts(decoded);
        } else {
          throw Exception('Không có mạng và không có cache.');
        }
      }
      rethrow;
    }
  }

  // =========================================================================
  // 2. GET DETAIL
  // =========================================================================
  Future<Product> getProductById(int id) async {
    try {
      final response = await _productService.getProductById(id);

      if (response.isSuccessful) {
        final dynamic data = response.body;
        // Xử lý nếu bọc trong 'data'
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return Product.fromJson(data['data']);
        }
        return Product.fromJson(data);
      } else {
        throw Exception('Không tìm thấy sản phẩm $id');
      }
    } catch (e) {
      throw Exception('Lỗi lấy chi tiết: $e');
    }
  }

  // =========================================================================
  // 3. IMPORT STOCK
  // =========================================================================
  Future<bool> importStock(
    List<Map<String, dynamic>> items,
    String note,
  ) async {
    final body = {
      "userId": 1, // Hardcode tạm thời
      "note": note,
      "items": items,
    };

    try {
      print("🔵 [Repo] Đang gửi nhập kho...");
      final response = await _productService.importStock(body);

      if (response.isSuccessful) {
        print("🟢 [Repo] Nhập kho thành công!");
        return true;
      } else {
        print("❌ [Repo] Lỗi: ${response.error}");
        return false;
      }
    } catch (e) {
      throw Exception("Lỗi kết nối khi nhập kho: $e");
    }
  }
}
