import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'core/config/api_config.dart';

class OrderService {
  // ========================================================================
  //                               HELPERS
  // ========================================================================

  // Helper: Lấy Header có Token xác thực
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper: Xử lý lỗi chung
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'Lỗi ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        message = body['message'] ?? body['title'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  // ========================================================================
  //                               CUSTOMER API
  // ========================================================================

  // 1. Lấy danh sách khách hàng
  Future<List<Customer>> getCustomers({required String storeId}) async {
    final uri = Uri.parse(
      ApiConfig.customers,
    ).replace(queryParameters: {'storeId': storeId});

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Không thể tải khách hàng: $e');
    }
  }

  // 2. Tạo khách hàng mới
  Future<Customer> createCustomer({
    required String name,
    required String phone,
    required String address,
    required String storeId,
  }) async {
    final url = Uri.parse(ApiConfig.customers);
    final body = {
      "fullName": name,
      "phoneNumber": phone,
      "address": address,
      "storeId": storeId,
      "currentDebt": 0,
    };

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        return Customer(
          id: resData['id'] ?? resData['customerId'] ?? '',
          name: name,
          phone: phone,
          address: address,
          currentDebt: 0,
        );
      } else {
        _handleError(response);
        throw Exception("Tạo thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  // ========================================================================
  //                               DEBT & ACCOUNTING API
  // ========================================================================

  // 3. Trả nợ (Thanh toán nợ)
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

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _handleError(response);
        throw Exception('Lỗi thanh toán');
      }
    } catch (e) {
      throw Exception('Lỗi thanh toán: $e');
    }
  }

  // [ĐÃ SỬA] 4. Lấy lịch sử ghi nợ (Debt History)
  Future<List<DebtLog>> getDebtHistory(String customerId,
      {required String storeId}) async {
    // Sửa lỗi: Sử dụng hàm helper từ ApiConfig thay vì gọi baseUrl
    final uri = Uri.parse(
      '${ApiConfig.debtHistory(customerId)}?storeId=$storeId',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DebtLog.fromJson(json)).toList();
      } else {
        if (response.statusCode == 404) return [];
        _handleError(response);
        return [];
      }
    } catch (e) {
      print("Lỗi tải lịch sử nợ: $e");
      return [];
    }
  }

  // [ĐÃ SỬA] 5. Lấy lịch sử đơn hàng của khách (Order History)
  Future<List<Order>> getOrdersByCustomer(String customerId,
      {required String storeId}) async {
    // Sửa lỗi: Sử dụng hàm helper từ ApiConfig thay vì gọi baseUrl
    final uri = Uri.parse(
      '${ApiConfig.ordersByCustomer(customerId)}?storeId=$storeId',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        if (response.statusCode == 404) return [];
        _handleError(response);
        return [];
      }
    } catch (e) {
      print("Lỗi tải đơn hàng: $e");
      return [];
    }
  }
}
