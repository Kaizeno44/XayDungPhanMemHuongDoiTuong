import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/api_service.dart';

class FCMService {
  // Singleton
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  // 1. Chỉ khởi tạo & xin quyền (Không gọi API ở đây nữa)
  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // In ra token để debug chơi thôi (xem log)
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('🔑 FCM Token hiện tại (Init): $token');
      }
    } catch (e) {
      print('⚠️ Lỗi lấy token lúc init: $e');
    }

    // Lắng nghe tin nhắn khi app đang mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📩 Nhận tin nhắn: ${message.notification?.title}');
      }
    });
  }

  // 2. Hàm này mới gọi API (Sẽ được gọi sau khi Login)
  Future<void> syncTokenWithServer(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        if (kDebugMode) {
          print('🔄 Đang đồng bộ Token cho User ID: $userId');
        }

        // Gọi API gửi cả userId và deviceToken
        await _apiService.post(
          '/api/users/device-token',
          data: {
            'userId': userId, // Quan trọng: Phải có dòng này!
            'deviceToken': token,
            'platform': defaultTargetPlatform.name, // "android" hoặc "ios"
          },
        );

        if (kDebugMode) {
          print('✅ Đã lưu Token thành công vào Database!');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi gửi token: $e');
      }
    }
  }
}
