import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ========================================================================
  // 1. CẤU HÌNH HOST (TỰ ĐỘNG PHÁT HIỆN MÔI TRƯỜNG)
  // ========================================================================
  static String get _host {
    if (kReleaseMode) {
      return "api.bizflow.com"; // Domain Production (nếu có)
    }

    // Android Emulator: 10.0.2.2 gọi ra localhost máy tính
    if (!kIsWeb && Platform.isAndroid) {
      return "10.0.2.2";
    }

    // iOS Simulator / Web / Windows App: 127.0.0.1 (localhost)
    return "127.0.0.1";
  }

  // ========================================================================
  // 2. BASE URL (THEO MICROSERVICES)
  // Lưu ý: Port phải khớp với launchSettings.json của từng Service
  // ========================================================================

  // Identity Service (Port 5001)
  static String get identityBaseUrl => "http://$_host:5001";

  // Product Service (Port 5002)
  static String get productBaseUrl => "http://$_host:5002";

  // Order Service (Port 5103 - Chứa cả Order, Customer, Accounting, Report)
  static String get orderBaseUrl => "http://$_host:5103";

  // ========================================================================
  // 3. SIGNALR (REAL-TIME)
  // ========================================================================
  static String get productHub => "$productBaseUrl/hubs/products";
  static String get notificationHub => "$orderBaseUrl/hubs/notification";

  // ========================================================================
  // 4. API ENDPOINTS
  // ========================================================================

  // ------------------------------------------------------------------------
  // A. AUTH & IDENTITY
  // ------------------------------------------------------------------------
  static String get login => "$identityBaseUrl/api/Auth/login";
  static String get register => "$identityBaseUrl/api/Auth/register";
  static String get userProfile => "$identityBaseUrl/api/Users/profile";

  // ------------------------------------------------------------------------
  // B. KHO HÀNG (PRODUCTS)
  // ------------------------------------------------------------------------
  static String get products => "$productBaseUrl/api/Products";
  static String get categories => "$productBaseUrl/api/Categories";
  static String get stockImports => "$productBaseUrl/api/StockImports";
  static String get checkStock => "$productBaseUrl/api/Products/check-stock";
  static String get lowStock => "$products/low-stock";
  // Helper: Lấy chi tiết sản phẩm
  static String productDetail(int id) => "$products/$id";

  // ------------------------------------------------------------------------
  // C. BÁN HÀNG & KHÁCH HÀNG (ORDERS)
  // ------------------------------------------------------------------------
  static String get orders => "$orderBaseUrl/api/Orders";
  static String get customers => "$orderBaseUrl/api/Customers";

  // Helper: Lấy lịch sử đơn hàng của 1 khách (Order History)
  // Endpoint: GET /api/orders/customer/{customerId}
  static String ordersByCustomer(String customerId) =>
      "$orders/customer/$customerId";

  // Helper: Trả nợ (Thanh toán công nợ)
  static String get payDebt => "$customers/pay-debt";

  // ------------------------------------------------------------------------
  // D. KẾ TOÁN & TÀI CHÍNH (ACCOUNTING) - [MỚI]
  // ------------------------------------------------------------------------
  static String get accounting => "$orderBaseUrl/api/Accounting";

  // Sổ quỹ (Cash Book): Dòng tiền vào (Đơn hàng + Thu nợ)
  static String get cashBook => "$accounting/cash-book";

  // Biểu đồ doanh thu 7 ngày
  static String get revenueStats => "$accounting/revenue-stats";

  // Lịch sử ghi nợ/trả nợ của 1 khách hàng
  // Endpoint: GET /api/accounting/debt-history/{customerId}
  static String debtHistory(String customerId) =>
      "$accounting/debt-history/$customerId";

  // ------------------------------------------------------------------------
  // E. DASHBOARD & BÁO CÁO
  // ------------------------------------------------------------------------
  static String get dashboardStats => "$orderBaseUrl/api/Dashboard/stats";
  static String get reports => "$orderBaseUrl/api/Reports";

  // ========================================================================
  // 5. HEADERS MẶC ĐỊNH
  // ========================================================================
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
}
