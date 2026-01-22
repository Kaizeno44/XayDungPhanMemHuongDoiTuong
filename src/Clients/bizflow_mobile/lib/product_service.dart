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
    @Query('categoryId') int? categoryId,
    @Query('page') int page = 1,
    @Query('pageSize') int pageSize = 10,
  });

  // 2. Lấy chi tiết sản phẩm
  @Get(path: '/Products/{id}')
  Future<Response<dynamic>> getProductById(@Path('id') int id);

  // 3. Nhập kho
  @Post(path: '/Stock/import')
  Future<Response<dynamic>> importStock(@Body() Map<String, dynamic> body);

  // 4. 👇 KIỂM TRA TỒN KHO (Hàm này đang gây lỗi vì thiếu trong file chopper)
  @Post(path: '/Products/check-stock')
  Future<Response<dynamic>> checkStock(@Body() Map<String, dynamic> body);
}
