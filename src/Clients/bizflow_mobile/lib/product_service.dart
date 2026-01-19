import 'package:chopper/chopper.dart';

part 'product_service.chopper.dart';

// 1. Đổi BaseUrl thành '/api' để dùng chung cho Products và Stock
@ChopperApi(baseUrl: '/api')
abstract class ProductService extends ChopperService {
  static ProductService create([ChopperClient? client]) =>
      _$ProductService(client);

  // 2. Cập nhật API Get Products (thêm path /Products)
  @Get(path: '/Products')
  Future<Response<dynamic>> getProducts({
    @Query('keyword') String? keyword,
    @Query('categoryId') int? categoryId,
    @Query('page') int page = 1,
    @Query('pageSize') int pageSize = 10,
  });

  // 3. Thêm API Get Detail
  @Get(path: '/Products/{id}')
  Future<Response<dynamic>> getProductById(@Path('id') int id);

  // 4. Thêm API Nhập kho (Endpoint: /api/Stock/import)
  @Post(path: '/Stock/import')
  Future<Response<dynamic>> importStock(@Body() Map<String, dynamic> body);
}
