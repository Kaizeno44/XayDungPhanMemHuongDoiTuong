import 'dart:async';
import 'package:bizflow_mobile/core/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:signalr_core/signalr_core.dart';

// --- IMPORTS MODEL & PROVIDERS ---
import '../../models/events/stock_update_event.dart';
import '../../providers/auth_provider.dart'; // Để lấy Token chuẩn xác
import 'notification_service.dart'; // Để hiện thông báo

part 'signalr_service.g.dart';

// keepAlive: true -> Giữ kết nối luôn sống dù đổi màn hình
@Riverpod(keepAlive: true)
class SignalRService extends _$SignalRService {
  HubConnection? _hubConnection;

  // 1. Tạo "Đài phát thanh" (Stream) cho sự kiện tồn kho
  final _stockUpdateController = StreamController<StockUpdateEvent>.broadcast();

  // Public Stream để UI lắng nghe
  Stream<StockUpdateEvent> get stockUpdateStream =>
      _stockUpdateController.stream;

  @override
  Future<void> build() async {
    // Tự động dọn dẹp khi Service bị hủy (VD: User đăng xuất hoàn toàn)
    ref.onDispose(() {
      _stockUpdateController.close();
      _closeConnection();
    });
  }

  // --- HÀM KẾT NỐI ---
  Future<void> connect() async {
    if (_hubConnection?.state == HubConnectionState.connected) {
      debugPrint("⚠️ SignalR Service: Đã kết nối rồi.");
      return;
    }

    try {
      // 2. Lấy Token từ AuthProvider (Chuẩn hơn dùng Hive trực tiếp)
      // Lý do: Đảm bảo lấy đúng Token của User đang đăng nhập hiện tại
      final authState = ref.read(authNotifierProvider);
      final token = authState.token;

      if (token == null) {
        debugPrint(
          "⚠️ SignalR Service: Không tìm thấy Token (User chưa login).",
        );
        return;
      }

      debugPrint(
        '🔄 SignalR Service: Đang kết nối tới ${ApiConfig.productHub}...',
      );

      // 3. Cấu hình Hub
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            ApiConfig.productHub,
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
              logging: (level, message) => debugPrint('SignalR Log: $message'),
            ),
          )
          .withAutomaticReconnect()
          .build();

      // 4. Lắng nghe trạng thái kết nối
      _hubConnection?.onclose(
        (error) => debugPrint('❌ SignalR Closed: $error'),
      );
      _hubConnection?.onreconnecting(
        (_) => debugPrint('🔸 SignalR Reconnecting...'),
      );
      _hubConnection?.onreconnected(
        (_) => debugPrint('✅ SignalR Reconnected!'),
      );

      // --- 5. ĐĂNG KÝ SỰ KIỆN (HANDLERS) ---

      // A. Sự kiện: Cập nhật tồn kho (Real-time Inventory)
      _hubConnection?.on('ReceiveStockUpdate', (arguments) {
        _handleStockUpdate(arguments);
      });

      // B. Sự kiện: Thông báo đơn hàng (Real-time Notification)
      _hubConnection?.on('ReceiveOrderNotification', (arguments) {
        _handleOrderNotification(arguments);
      });

      // 6. Bắt đầu kết nối
      await _hubConnection?.start();
      debugPrint('✅ SignalR Service: Connected (Global)!');
    } catch (e) {
      debugPrint('🔥 SignalR Service Error: $e');
    }
  }

  // --- XỬ LÝ LOGIC ---

  void _handleStockUpdate(List<dynamic>? arguments) {
    try {
      if (arguments == null || arguments.length < 2) return;

      final int productId = int.tryParse(arguments[0].toString()) ?? 0;
      final double newQuantity =
          double.tryParse(arguments[1].toString()) ?? 0.0;

      debugPrint("🔔 Stock Update: SP $productId -> $newQuantity");

      // Bắn sự kiện vào Stream -> UI tự cập nhật
      _stockUpdateController.add(
        StockUpdateEvent(productId: productId, newQuantity: newQuantity),
      );
    } catch (e) {
      debugPrint("⚠️ SignalR Stock Parse Error: $e");
    }
  }

  void _handleOrderNotification(List<dynamic>? arguments) {
    try {
      if (arguments == null || arguments.length < 2) return;

      final String orderId = arguments[0].toString();
      final String message = arguments[1].toString();

      debugPrint("🔔 Order Notification: $message (ID: $orderId)");

      // Gọi NotificationService để hiện thông báo trên thanh trạng thái
      ref
          .read(notificationServiceProvider)
          .showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID ngẫu nhiên
            title: '📦 Đơn hàng thành công!',
            body: 'Mã đơn #$orderId: $message',
          );
    } catch (e) {
      debugPrint("⚠️ SignalR Notification Parse Error: $e");
    }
  }

  // --- NGẮT KẾT NỐI ---
  Future<void> disconnect() async {
    await _closeConnection();
  }

  Future<void> _closeConnection() async {
    if (_hubConnection != null) {
      await _hubConnection?.stop();
      _hubConnection = null;
      debugPrint('🛑 SignalR Service: Stopped.');
    }
  }
}
