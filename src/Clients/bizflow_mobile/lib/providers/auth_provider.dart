import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../core/api_service.dart'; // Import ApiService mới
import '../services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService; // Inject ApiService
  final String _authBoxName = 'authBox';

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isAuthCheckComplete = false;

  // --- GETTERS (Phục hồi các getter bị thiếu) ---
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isAuthCheckComplete => _isAuthCheckComplete;
  String? get role => _currentUser?.role;

  // Constructor nhận ApiService
  AuthProvider(this._apiService) {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      var box = await Hive.openBox(_authBoxName);
      _token = box.get('token');
      final userData = box.get('user');

      if (userData != null) {
        _currentUser = User.fromJson(Map<String, dynamic>.from(userData));
      }
    } catch (e) {
      print("⚠️ Lỗi đọc cache auth: $e");
      var box = await Hive.openBox(_authBoxName);
      await box.clear();
    } finally {
      _isAuthCheckComplete = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. GỌI API QUA CHOPPER
      final response = await _apiService.authService.login({
        'email': email,
        'password': password,
      });

      // 2. XỬ LÝ KẾT QUẢ
      if (response.isSuccessful) {
        final body = response.body; // Map<String, dynamic>

        // Map dữ liệu từ API về Model (Tùy chỉnh theo JSON thực tế của bạn)
        // Ví dụ: { "token": "...", "user": { ... } }
        _token = body['token'];
        _currentUser = User.fromJson(
          body['user'],
        ); // Cần đảm bảo JSON khớp Model User

        // 3. LƯU VÀO HIVE & PREFS
        var box = await Hive.openBox(_authBoxName);
        await box.put('token', _token);
        await box.put('user', {
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'fullName': _currentUser!.fullName,
          'role': _currentUser!.role,
          'storeId': _currentUser!.storeId,
        });

        // Lưu token vào SharedPreferences cho Interceptor dùng
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
          await prefs.setString('access_token', _token!);
        }

        // Gửi Token FCM
        if (_currentUser != null) {
          FCMService().syncTokenWithServer(_currentUser!.id.toString());
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Xử lý lỗi từ server
        final error = response.error;
        print("Login error: $error");
        throw Exception("Đăng nhập thất bại");
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Login exception: $e");
      rethrow; // Ném lỗi ra để UI hiển thị dialog
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    // Xóa Hive
    var box = await Hive.openBox(_authBoxName);
    await box.clear();

    // Xóa SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    notifyListeners();
  }
}
