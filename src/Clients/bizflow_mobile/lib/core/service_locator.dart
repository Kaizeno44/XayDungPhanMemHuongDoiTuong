import 'package:chopper/chopper.dart' hide Level;
import 'package:logging/logging.dart'; // Cần thiết để setup Logger

// Import các file trong dự án
// Lưu ý: Đảm bảo đường dẫn import đúng với vị trí file thực tế của bạn
import '../product_service.dart';
import '../product_repository.dart';

class ServiceLocator {
  static late final ChopperClient productClient;
  static late final ProductService productService;
  static late final ProductRepository productRepo;

  static void setup() {
    // 1. Cấu hình Logging để xem log API trong Console
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });

    // 2. Tạo Chopper Client (Quản lý kết nối mạng)
    productClient = ChopperClient(
      baseUrl: Uri.parse(
        'http://10.0.2.2:5000',
      ), // Dùng 10.0.2.2 cho Android Emulator
      services: [
        ProductService.create(), // Đăng ký Service
      ],
      converter: const JsonConverter(), // Tự động convert JSON
      interceptors: [
        HttpLoggingInterceptor(), // Tự động log request/response
      ],
    );

    // 3. Tạo Service Instance từ Client
    productService = productClient.getService<ProductService>();

    // 4. Tạo Repository (Lớp xử lý logic dữ liệu & Cache)
    productRepo = ProductRepository(productService);
  }
}
