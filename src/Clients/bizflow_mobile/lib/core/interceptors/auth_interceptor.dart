import 'dart:async';
import 'package:chopper/chopper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor implements RequestInterceptor {
  @override
  FutureOr<Request> onRequest(Request request) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token != null && token.isNotEmpty) {
      // --- THÊM DÒNG NÀY ĐỂ DEBUG ---
      print("🔐 AuthInterceptor: Đã tìm thấy Token! Đang gắn vào Header...");
      // In ra 10 ký tự đầu của token để kiểm tra (không in hết để bảo mật)
      print("🔐 Token: ${token.substring(0, 10)}...");

      return applyHeader(request, 'Authorization', 'Bearer $token');
    } else {
      print("⚠️ AuthInterceptor: Không tìm thấy Token!");
    }

    return request;
  }
}
