// lib/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'core/config/api_config.dart';

class OrderService {
  // 1. Hàm trả nợ (Giữ nguyên từ code cũ của bạn nếu có)
  Future<Map<String, dynamic>> payDebt({
    required String customerId,
    required double amount,
    required String storeId,
  }) async {
    final url = Uri.parse(ApiConfig.payDebt);
    final body = {
      "customerId": customerId,
      "amount": amount,
      "storeId": storeId,
    };

    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Lỗi thanh toán nợ');
    }
  }

  // 2. 👇 HÀM MỚI: Tạo khách hàng
  Future<Customer> createCustomer({
    required String name,
    required String phone,
    required String address,
    required String storeId,
  }) async {
    final url = Uri.parse(ApiConfig.customers); // URL API tạo khách hàng

    final body = {
      "fullName": name,
      "phoneNumber": phone,
      "address": address,
      "storeId": storeId, // Gán khách vào cửa hàng hiện tại
      "currentDebt": 0,
    };

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);

        // Backend trả về JSON có dạng: { "message": "...", "customerId": "..." }
        // Ta tạo ngay đối tượng Customer để trả về UI
        return Customer(
          id: resData['customerId'] ?? '',
          name: name,
          phone: phone,
          address: address,
          currentDebt: 0,
        );
      } else {
        // Xử lý lỗi từ Server (ví dụ: SĐT trùng)
        String errorMsg = response.body;
        try {
          final errJson = jsonDecode(response.body);
          errorMsg = errJson['message'] ?? errJson['title'] ?? response.body;
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }
}
