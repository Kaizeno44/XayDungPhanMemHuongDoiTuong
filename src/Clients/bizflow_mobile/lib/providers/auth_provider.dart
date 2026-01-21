import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // [MỚI] Import Riverpod

// --- IMPORTS ---
import '../models.dart'; // Đảm bảo User model đã được cập nhật id là String
import '../core/api_service.dart';
import '../core/service_locator.dart';
import '../services/fcm_service.dart';

// --- 1. PROVIDER CŨ (Logic chính) ---
class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final String _authBoxName = 'authBox';

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isAuthCheckComplete = false;

  // --- Getters ---
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isAuthCheckComplete => _isAuthCheckComplete;
  String? get role => _currentUser?.role;

  AuthProvider(this._apiService) {
    _loadAuthData();
  }

  // --- Load dữ liệu từ Cache khi mở App ---
  Future<void> _loadAuthData() async {
    try {
      final box = await Hive.openBox(_authBoxName);
      _token = box.get('token');
      final userData = box.get('user');

      if (userData != null) {
        // Chuyển đổi Map<dynamic, dynamic> sang Map<String, dynamic> an toàn
        final jsonMap = Map<String, dynamic>.from(userData);
        _currentUser = User.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi đọc cache auth: $e");
      // Nếu lỗi data rác -> Xóa sạch
      final box = await Hive.openBox(_authBoxName);
      await box.clear();
      _token = null;
      _currentUser = null;
    } finally {
      _isAuthCheckComplete = true;
      notifyListeners();
    }
  }

  // --- Đăng nhập ---
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Gọi API
      final response = await _apiService.authService.login({
        'email': email,
        'password': password,
      });

      // 2. Xử lý kết quả
      if (response.isSuccessful) {
        final body = response.body; // Map<String, dynamic>

        final newToken = body['token'] as String?;
        final userJson = body['user'];

        if (newToken == null || userJson == null) {
          throw Exception("Dữ liệu trả về không hợp lệ (thiếu token/user)");
        }

        _token = newToken;
        // Parse User (Model User cần có id là String)
        _currentUser = User.fromJson(userJson);

        // 3. Lưu Cache
        await _saveAuthData(_token!, _currentUser!);

        // 4. Đồng bộ FCM (QUAN TRỌNG: ID giờ là String nên không ép kiểu int nữa)
        if (_currentUser != null) {
          _syncFCM(_currentUser!.id);
        }

        _isLoading = false;
        notifyListeners(); // Báo cho Router chuyển trang
        return true;
      } else {
        // Parse lỗi từ Server
        String errorMsg = "Đăng nhập thất bại";
        if (response.error != null) {
          try {
            final errorBody = response.error as Map<String, dynamic>;
            if (errorBody.containsKey('message')) {
              errorMsg = errorBody['message'];
            }
          } catch (_) {
            errorMsg = "Lỗi Server: ${response.statusCode}";
          }
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("❌ Login Exception: $e");
      rethrow;
    }
  }

  // --- Helper: Lưu dữ liệu ---
  Future<void> _saveAuthData(String token, User user) async {
    final box = await Hive.openBox(_authBoxName);
    await box.put('token', token);
    await box.put('user', {
      'id': user.id, // Lưu String ID
      'email': user.email,
      'fullName': user.fullName,
      'role': user.role,
      'storeId': user.storeId,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // --- Helper: Sync FCM (Đã sửa nhận String) ---
  void _syncFCM(String userId) {
    // Không cần .toString() vì userId đã là String
    FCMService().syncTokenWithServer(userId).catchError((err) {
      debugPrint("⚠️ Lỗi Sync FCM: $err");
    });
  }

  // --- Đăng xuất ---
  Future<void> logout() async {
    try {
      _token = null;
      _currentUser = null;

      final box = await Hive.openBox(_authBoxName);
      await box.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      // await FCMService().deleteToken(); // Optional
    } catch (e) {
      debugPrint("⚠️ Lỗi khi logout: $e");
    } finally {
      notifyListeners(); // Router sẽ tự động đá về Login
    }
  }
}

// --- 2. CẦU NỐI RIVERPOD (QUAN TRỌNG CHO GOROUTER) ---
final authNotifierProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider(ServiceLocator.apiService);
});
