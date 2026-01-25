import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'core/config/api_config.dart';

class OrderService {
  // Helper: Lấy Header có Token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

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
        throw Exception('Lỗi ${response.statusCode}: Không thể tải khách hàng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // 2. Trả nợ
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
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Lỗi thanh toán nợ');
      }
    } catch (e) {
      throw Exception('Lỗi thanh toán: $e');
    }
  }

  // 3. Tạo khách hàng
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
          id: resData['customerId'] ?? resData['id'] ?? '',
          name: name,
          phone: phone,
          address: address,
          currentDebt: 0,
        );
      } else {
        throw Exception("Tạo thất bại: ${response.body}");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }
}
