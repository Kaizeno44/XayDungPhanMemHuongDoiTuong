import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart'; // [MỚI] Import service này

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final String _authBoxName = 'authBox';

  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    var box = await Hive.openBox(_authBoxName);
    _token = box.get('token');
    final userData = box.get('user');
    if (userData != null) {
      _currentUser = User.fromJson(Map<String, dynamic>.from(userData));
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response.token;
      _currentUser = response.user;

      var box = await Hive.openBox(_authBoxName);
      await box.put('token', _token);
      await box.put('user', {
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'fullName': _currentUser!.fullName,
        'role': _currentUser!.role,
        'storeId': _currentUser!.storeId,
      });

      // 👇 [QUAN TRỌNG] Gửi Token sau khi Login thành công 👇
      if (_currentUser != null) {
        // Gọi hàm đồng bộ token, truyền ID của user vào
        FCMService().syncTokenWithServer(_currentUser!.id.toString());
      }
      // -----------------------------------------------------

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    var box = await Hive.openBox(_authBoxName);
    await box.clear();
    notifyListeners();
  }
}
