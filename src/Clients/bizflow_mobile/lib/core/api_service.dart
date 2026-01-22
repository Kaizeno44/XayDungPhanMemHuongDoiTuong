import 'package:bizflow_mobile/product_service.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart'; // Để dùng kDebugMode

// 1. Import Interceptor và Config
import 'config/api_config.dart';
import 'interceptors/auth_interceptor.dart';

// 2. Import các Services (File .dart gốc, không phải file .chopper.dart)
import '../services/auth_service.dart';
// import '../services/order_service.dart'; // Bỏ comment khi bạn tạo OrderService

class ApiService {
  // --- CLIENTS ---
  // Client riêng cho Identity Server (Login/Register) - Không gửi kèm Token
  late final ChopperClient _identityClient;

  // Client cho Business Services (Product, Order...) - Tự động gửi Token
  late final ChopperClient _businessClient;

  // --- EXPOSED SERVICES (Để Provider/Repository gọi) ---
  late final AuthService authService;
  late final ProductService productService;
  // late final OrderService orderService;

  ApiService() {
    // -------------------------------------------------------------------------
    // 1. CẤU HÌNH IDENTITY CLIENT (Port 5000)
    // -------------------------------------------------------------------------
    // Dùng cho: Login, Register.
    // Đặc điểm: KHÔNG dùng AuthInterceptor (vì chưa có token hoặc đang lấy token).
    _identityClient = ChopperClient(
      baseUrl: Uri.parse('http://10.0.2.2:5000'), // IP Identity Server
      services: [AuthService.create()],
      converter: const JsonConverter(),
      interceptors: [
        HttpLoggingInterceptor(), // Log request/response để debug
        // CurlInterceptor(), // Dùng cái này nếu muốn copy request ra cURL
      ],
    );

    // -------------------------------------------------------------------------
    // 2. CẤU HÌNH BUSINESS CLIENT (Port 5001/5002 hoặc Gateway)
    // -------------------------------------------------------------------------
    // Dùng cho: Product, Order, Report...
    // Đặc điểm: CÓ dùng AuthInterceptor để tự động đính kèm JWT Token.
    _businessClient = ChopperClient(
      // Lưu ý: Nếu bạn chạy Microservices qua Gateway (Ocelot/YARP), hãy trỏ vào Gateway.
      // Nếu chạy lẻ, tạm thời trỏ vào Product API.
      baseUrl: Uri.parse(ApiConfig.productBaseUrl),
      services: [
        ProductService.create(),
        // OrderService.create(),
      ],
      converter: const JsonConverter(),
      interceptors: [
        AuthInterceptor(), // <--- QUAN TRỌNG: Tự động chèn 'Bearer Token'
        HttpLoggingInterceptor(),
      ],
    );

    // -------------------------------------------------------------------------
    // 3. KHỞI TẠO SERVICES
    // -------------------------------------------------------------------------
    authService = _identityClient.getService<AuthService>();
    productService = _businessClient.getService<ProductService>();
    // orderService = _businessClient.getService<OrderService>();

    if (kDebugMode) {
      print('🚀 ApiService initialized with Chopper Clients');
    }
  }

  Future<void> post(String s, {required Map<String, String> data}) async {}
}
