import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';

import '../core/result.dart';
import '../models/product.dart';
// Import ProductService (Sửa đường dẫn nếu file này nằm ở nơi khác)
import '../product_service.dart';

class ProductRepository {
  final ProductService _productService;
  final String _productCacheBox = 'productCache';
  final String _cacheKey = 'all_products';

  ProductRepository(this._productService);

  // =========================================================================
  // 1. GET PRODUCTS (Offline First + Search)
  // =========================================================================
  Future<Result<List<Product>>> getProducts({
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _productService.getProducts(
        keyword: keyword,
        page: page,
        pageSize: pageSize,
      );

      if (response.isSuccessful) {
        final products = _parseProducts(response.body);

        // Cache lại nếu là trang đầu và không tìm kiếm
        if (page == 1 && (keyword == null || keyword.isEmpty)) {
          await _saveToCache(response.body);
        }

        return Success(products);
      } else {
        return Failure(
          'Lỗi máy chủ (${response.statusCode}): ${response.error}',
        );
      }
    } catch (e) {
      // Xử lý Offline
      if (_isNetworkError(e)) {
        if (keyword == null || keyword.isEmpty) {
          try {
            final cachedProducts = await _loadFromCache();
            if (cachedProducts.isNotEmpty) {
              return Success(cachedProducts);
            }
          } catch (_) {
            // Bỏ qua lỗi cache
          }
        }
        return Failure(
          'Không có kết nối Internet và không có dữ liệu lưu trữ.',
        );
      }
      return Failure('Lỗi không xác định: $e');
    }
  }

  // =========================================================================
  // 2. GET PRODUCT DETAIL
  // =========================================================================
  Future<Result<Product>> getProductById(int id) async {
    try {
      final response = await _productService.getProductById(id);

      if (response.isSuccessful) {
        final dynamic data = response.body;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return Success(Product.fromJson(data['data']));
        }
        return Success(Product.fromJson(data));
      } else {
        return Failure('Không tìm thấy sản phẩm (Lỗi ${response.statusCode})');
      }
    } catch (e) {
      return Failure('Lỗi kết nối: $e');
    }
  }

  // =========================================================================
  // 3. CHECK STOCK (Kiểm tra tồn kho)
  // =========================================================================
  Future<Result<String>> checkStock(
    int productId,
    int unitId,
    double quantity,
  ) async {
    try {
      final response = await _productService.checkStock({
        // 👇 [ĐÃ SỬA LỖI] Khai báo rõ kiểu List chứa Map<String, dynamic>
        'requests': <Map<String, dynamic>>[
          {'productId': productId, 'unitId': unitId, 'quantity': quantity},
        ],
      });

      if (response.isSuccessful) {
        final body = response.body;

        // Parse kết quả trả về
        if (body is List && body.isNotEmpty) {
          final item = body.first;
          if (item['isAvailable'] == true) return const Success("Còn hàng");
          return Failure(item['message'] ?? 'Hết hàng');
        } else if (body is Map<String, dynamic>) {
          if (body['isAvailable'] == true) return const Success("Còn hàng");
          return Failure(body['message'] ?? 'Hết hàng');
        }

        return const Success("Kiểm tra thành công");
      }
      return Failure('Lỗi kiểm tra tồn kho: ${response.statusCode}');
    } catch (e) {
      return Failure('Lỗi kết nối: $e');
    }
  }

  // =========================================================================
  // 4. HELPER METHODS (Private)
  // =========================================================================

  List<Product> _parseProducts(dynamic responseBody) {
    List<dynamic> listData = [];

    if (responseBody is List) {
      listData = responseBody;
    } else if (responseBody is Map<String, dynamic>) {
      if (responseBody.containsKey('data')) {
        listData = responseBody['data'];
      } else if (responseBody.containsKey('items')) {
        listData = responseBody['items'];
      }
    }

    return listData.map((json) => Product.fromJson(json)).toList();
  }

  bool _isNetworkError(Object e) {
    return e is SocketException ||
        e is IOException ||
        e.toString().contains('Connection failed');
  }

  Future<void> _saveToCache(dynamic data) async {
    try {
      var box = await Hive.openBox(_productCacheBox);
      await box.put(_cacheKey, jsonEncode(data));
      print('✅ [Repo] Đã lưu cache sản phẩm.');
    } catch (e) {
      print('⚠️ [Repo] Lỗi lưu cache: $e');
    }
  }

  Future<List<Product>> _loadFromCache() async {
    print('🔸 [Repo] Đang tải từ Cache...');
    var box = await Hive.openBox(_productCacheBox);
    final String? cachedString = box.get(_cacheKey);

    if (cachedString != null) {
      final dynamic decoded = jsonDecode(cachedString);
      return _parseProducts(decoded);
    }
    return [];
  }
}
