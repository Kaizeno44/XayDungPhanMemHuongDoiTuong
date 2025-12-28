import 'dart:convert';
import 'package:flutter/foundation.dart'; // Để dùng debugPrint
import 'package:http/http.dart' as http;

class OrderService {
  // ⚠️ LƯU Ý:
  // - Máy ảo Android: dùng "10.0.2.2"
  // - Máy thật / iOS: dùng IP LAN của máy tính (VD: "192.168.1.x")
  static const String baseUrl = "http://10.0.2.2:5103";

  Future<Map<String, dynamic>> payDebt({
    required String customerId,
    required double amount,
    String? storeId,
  }) async {
    final url = Uri.parse('$baseUrl/api/Customers/pay-debt');

    // Dữ liệu gửi đi
    final bodyRequest = {
      "customerId": customerId,
      "amount": amount,
      "storeId": storeId,
      "orderId": null,
    };

    // [Log] In ra console để kiểm tra
    debugPrint("🔵 Đang gọi API: $url");
    debugPrint("📦 Body gửi đi: ${jsonEncode(bodyRequest)}");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json", "accept": "*/*"},
            body: jsonEncode(bodyRequest),
          )
          .timeout(const Duration(seconds: 30)); // Thêm timeout 30s

      debugPrint("🟢 Response Status: ${response.statusCode}");
      debugPrint("📄 Response Body: ${response.body}");

      // 1. Trường hợp thành công (200 - 299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Kiểm tra nếu body rỗng
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body);
      }
      // 2. Trường hợp lỗi (400, 404, 500...)
      else {
        // 🛠️ QUAN TRỌNG: Xử lý lỗi an toàn để tránh Crash App
        String errorMessage;

        try {
          // Cố gắng đọc format JSON chuẩn từ Backend
          final errorJson = jsonDecode(response.body);

          // Ưu tiên lấy message từ các trường thường gặp
          errorMessage =
              errorJson['message'] ??
              errorJson['title'] ??
              errorJson['error'] ??
              "Lỗi không xác định từ Server";

          // Nếu backend trả về danh sách lỗi chi tiết (errors validation)
          if (errorJson['errors'] != null) {
            errorMessage += "\nChi tiết: ${errorJson['errors'].toString()}";
          }
        } catch (e) {
          // ⚠️ Nếu body KHÔNG PHẢI JSON (VD: text trần "Khách hàng không tồn tại")
          // Thì lấy nguyên văn text đó làm thông báo lỗi
          errorMessage = response.body.isNotEmpty
              ? response.body
              : "Lỗi kết nối: ${response.statusCode}";
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint("🔴 Lỗi xảy ra: $e");

      // Làm sạch thông báo lỗi (bỏ chữ "Exception: " thừa nếu có)
      String cleanError = e.toString().replaceAll("Exception: ", "");
      throw Exception(cleanError);
    }
  }
}
