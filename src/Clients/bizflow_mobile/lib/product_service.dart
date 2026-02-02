import 'package:chopper/chopper.dart';

part 'product_service.chopper.dart';

@ChopperApi(baseUrl: '/api')
abstract class ProductService extends ChopperService {
  static ProductService create([ChopperClient? client]) =>
      _$ProductService(client);

  // 1. Lấy danh sách sản phẩm
  @Get(path: '/Products')
  Future<Response<dynamic>> getProducts({
    @Query('keyword') String? keyword,
    @Query('storeId') String? storeId, // 👈 Thêm StoreId
    @Query('categoryId') int? categoryId,
    @Query('page') int page = 1,
    @Query('pageSize') int pageSize = 10,
  });

  // 2. Lấy chi tiết sản phẩm
  @Get(path: '/Products/{id}')
  Future<Response<dynamic>> getProductById(@Path('id') int id);

  // 3. Tạo phiếu nhập kho (Quan trọng: Đã sửa lại path cho đúng với Controller)
  // Backend: [HttpPost] tại api/StockImports
  @Post(path: '/StockImports')
  Future<Response<dynamic>> importStock(@Body() Map<String, dynamic> body);

  // 4. Lấy lịch sử nhập kho (Bổ sung thêm hàm này cho màn hình History)
  // Backend: [HttpGet] tại api/StockImports?storeId=...
  @Get(path: '/StockImports')
  Future<Response<dynamic>> getStockHistory({
    @Query('storeId') required String storeId,
  });

  // 5. Kiểm tra tồn kho
  // Backend: [HttpPost("check-stock")] tại api/Products/check-stock
  @Post(path: '/Products/check-stock')
  Future<Response<dynamic>> checkStock(@Body() Map<String, dynamic> body);
}
