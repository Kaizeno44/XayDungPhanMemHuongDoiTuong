// File: lib/order_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'core/config/api_config.dart'; // Import file config vừa tạo

class OrderService {
  // Hàm thanh toán công nợ
  Future<Map<String, dynamic>> payDebt({
    required String customerId,
    required double amount,
    String? storeId,
  }) async {
    // SỬ DỤNG APICONFIG
    final url = Uri.parse(ApiConfig.payDebt);

    final bodyRequest = {
      "customerId": customerId,
      "amount": amount,
      "storeId": storeId,
      "orderId": null,
    };

    debugPrint("🔵 [OrderService] Gọi API: $url");
    debugPrint("📦 Body: ${jsonEncode(bodyRequest)}");

    try {
      final response = await http
          .post(
            url,
            headers: ApiConfig.headers, // Dùng header chuẩn
            body: jsonEncode(bodyRequest),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint("🟢 Status: ${response.statusCode}");
      debugPrint("📄 Response: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body);
      } else {
        // Xử lý lỗi
        String errorMessage;
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage =
              errorJson['message'] ??
              errorJson['title'] ??
              errorJson['error'] ??
              "Lỗi Server: ${response.statusCode}";
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : "Lỗi kết nối: ${response.statusCode}";
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint("🔴 Lỗi: $e");
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}
