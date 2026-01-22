// ignore: depend_on_referenced_packages
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart'; // Để setup log
import 'package:bizflow_mobile/repositories/product_repository.dart';
// Import các file core và repository
import 'api_service.dart';

// Khởi tạo instance global của GetIt
final getIt = GetIt.instance;

class ServiceLocator {
  static void setup() {
    // 1. Cấu hình Logging (Chỉ cần setup 1 lần ở đây)
    _setupLogging();

    // 2. Đăng ký ApiService (Singleton)
    // ApiService này đã chứa logic AuthInterceptor và Chopper Client
    getIt.registerLazySingleton<ApiService>(() => ApiService());

    // 3. Đăng ký ProductRepository
    // Tự động lấy ProductService từ ApiService đã đăng ký ở trên để truyền vào Repo
    getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepository(getIt<ApiService>().productService),
    );

    // Bạn có thể đăng ký thêm các Repository khác ở đây
    // getIt.registerLazySingleton<OrderRepository>(
    //   () => OrderRepository(getIt<ApiService>().orderService),
    // );
  }

  // --- Helper Getters (Để gọi nhanh từ UI) ---

  // Cách dùng: ServiceLocator.apiService
  static ApiService get apiService => getIt<ApiService>();

  // Cách dùng: ServiceLocator.productRepo
  static ProductRepository get productRepo => getIt<ProductRepository>();

  // --- Private Helper ---
  static void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }
}
