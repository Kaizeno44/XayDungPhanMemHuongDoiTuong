import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models.dart';

class AuthService {
  Future<AuthResponse> login(String email, String password) async {
    final url = Uri.parse(ApiConfig.login);
    
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return AuthResponse.fromJson(data);
        }
        throw Exception('Dữ liệu phản hồi không hợp lệ');
      } else {
        // Xử lý trường hợp Backend trả về chuỗi văn bản thay vì JSON object
        try {
          final dynamic errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            throw Exception(errorData['message'] ?? 'Đăng nhập thất bại');
          } else {
            throw Exception(errorData.toString());
          }
        } catch (_) {
          // Nếu không phải JSON, lấy trực tiếp body làm thông báo lỗi
          throw Exception(response.body.isNotEmpty ? response.body : 'Đăng nhập thất bại (Lỗi ${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
