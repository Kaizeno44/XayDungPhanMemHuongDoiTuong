// File: lib/core/config/api_config.dart

class ApiConfig {
  // 1. Cấu hình Host (Thay đổi 1 nơi duy nhất)
  // - Máy ảo Android: "10.0.2.2"
  // - Máy thật / iOS: "192.168.1.x" (IP LAN của máy tính)
  static const String _host = "10.0.2.2";

  // 2. Định nghĩa Base URL cho từng Service (Microservices)
  static const String productBaseUrl =
      "http://$_host:5002"; // Service Sản phẩm
  static const String orderBaseUrl =
      "http://$_host:5103"; // Service Đơn hàng & Khách

  // 3. Định nghĩa các Endpoints (Đường dẫn cụ thể)

  // --- Nhóm Product ---
  static const String products = "$productBaseUrl/api/Products";
  static const String productHub = "$productBaseUrl/hubs/products"; // URL cho Product SignalR Hub

  // --- Nhóm Order & Customer ---
  static const String customers = "$orderBaseUrl/api/Customers";
  static const String payDebt = "$customers/pay-debt"; // API Thanh toán nợ
  static const String orders = "$orderBaseUrl/api/Orders";

  // 4. Headers mặc định
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  // ĐÚNG
  static String productDetail(int id) {
    return "$products/$id";
  }
}
