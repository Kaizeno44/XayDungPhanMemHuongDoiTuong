import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // 1. Cấu hình Host thông minh
  // - Android Emulator: 10.0.2.2
  // - iOS Simulator / Web: 127.0.0.1
  // - Máy thật: Thay bằng IP LAN của máy tính chạy Server (VD: 192.168.1.10)
  static String get _host {
    if (kReleaseMode) {
      return "api.bizflow.com"; // Domain Production (nếu có)
    }
    // Android Emulator dùng 10.0.2.2 để gọi ra localhost của máy tính
    if (!kIsWeb && Platform.isAndroid) {
      return "10.0.2.2";
    }
    // iOS Simulator và Web dùng localhost
    return "127.0.0.1";
  }

  // 2. Base URL cho từng Microservice
  // Lưu ý: Cổng (Port) phải khớp với file launchSettings.json của từng Service

  // Identity Service (Port 5001)
  static String get identityBaseUrl => "http://$_host:5001";

  // Product Service (Port 5002)
  static String get productBaseUrl => "http://$_host:5002";

  // Order Service (Port 5103 - Theo launchSettings.json bạn cung cấp)
  static String get orderBaseUrl => "http://$_host:5103";

  // static String get gatewayUrl => "http://$_host:5000";   // API Gateway (Dùng sau này nếu cần)

  // 3. SignalR Hubs (Real-time)
  static String get productHub => "$productBaseUrl/hubs/products";
  static String get notificationHub => "$orderBaseUrl/hubs/notification";

  // 4. API Endpoints chi tiết

  // --- NHÓM AUTH & IDENTITY ---
  static String get login => "$identityBaseUrl/api/Auth/login";
  static String get register => "$identityBaseUrl/api/Auth/register";
  static String get userProfile => "$identityBaseUrl/api/Users/profile";

  // --- NHÓM PRODUCT (KHO HÀNG) ---
  static String get products => "$productBaseUrl/api/Products";
  static String get categories => "$productBaseUrl/api/Categories";
  static String get stockImports =>
      "$productBaseUrl/api/StockImports"; // Endpoint nhập kho & lịch sử
  static String get checkStock => "$productBaseUrl/api/Products/check-stock";

  // Helper lấy chi tiết sản phẩm
  static String productDetail(int id) => "$products/$id";

  // --- NHÓM ORDER (BÁN HÀNG & BÁO CÁO) ---
  static String get orders => "$orderBaseUrl/api/Orders";
  static String get customers => "$orderBaseUrl/api/Customers";
  static String get payDebt => "$customers/pay-debt";

  // [MỚI] Endpoint lấy thống kê cho Dashboard
  // Trỏ về: BizFlow.OrderAPI/Controllers/DashboardController.cs -> [HttpGet("stats")]
  static String get dashboardStats => "$orderBaseUrl/api/Dashboard/stats";

  static String get reports => "$orderBaseUrl/api/Reports";

  // 5. Headers mặc định
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
}
