// File: lib/core/config/api_config.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // 1. Cấu hình Host thông minh
  // - Android Emulator: 10.0.2.2
  // - iOS Simulator / Web: 127.0.0.1
  // - Máy thật: Thay bằng IP LAN của bạn (VD: 192.168.1.5)
  static String get _host {
    if (kReleaseMode) {
      return "api.bizflow.com"; // Domain Production (nếu có)
    }
    if (Platform.isAndroid) {
      return "10.0.2.2";
    }
    return "127.0.0.1";
  }

  // 2. Base URL cho từng Microservice
  static String get productBaseUrl => "http://$_host:5002"; // Product Service
  static String get orderBaseUrl => "http://$_host:5103"; // Order Service
  static String get identityBaseUrl => "http://$_host:5001"; // Identity Service
  // static String get gatewayUrl => "http://$_host:5000";   // API Gateway (Nếu dùng)

  // 3. SignalR Hubs (Real-time)
  // [QUAN TRỌNG] Đường dẫn này dùng cho SignalRService
  static String get productHub => "$productBaseUrl/hubs/products";
  static String get notificationHub => "$orderBaseUrl/hubs/notification";

  // 4. API Endpoints

  // --- Nhóm Auth (Identity) ---
  static String get login => "$identityBaseUrl/api/Auth/login";
  static String get register => "$identityBaseUrl/api/Auth/register";
  static String get userProfile => "$identityBaseUrl/api/Users/profile";

  // --- Nhóm Product ---
  static String get products => "$productBaseUrl/api/Products";
  static String get categories => "$productBaseUrl/api/Categories";
  static String get stockImports => "$productBaseUrl/api/StockImports";

  // Helper lấy chi tiết sản phẩm
  static String productDetail(int id) => "$products/$id";

  // --- Nhóm Order & Customer ---
  static String get orders => "$orderBaseUrl/api/Orders";
  static String get customers => "$orderBaseUrl/api/Customers";
  static String get payDebt => "$customers/pay-debt";
  static String get reports => "$orderBaseUrl/api/Reports";

  // 5. Headers mặc định
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
}
