import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:bizflow_mobile/models.dart'; // Dùng đường dẫn package cho chắc chắn

// 👇 [QUAN TRỌNG] Sửa lại phần Import này
// Hãy thử bỏ comment dòng 1, nếu vẫn lỗi thì thử dòng 2 (tùy vào nơi bạn lưu file)

// Dòng 1: Nếu file nằm ở lib/services/signalr_service.dart
import 'package:bizflow_mobile/services/signalr_service.dart';

// Dòng 2: Nếu file nằm ở lib/core/services/signalr_service.dart
// import 'package:bizflow_mobile/core/services/signalr_service.dart';

part 'cart_controller.g.dart';

// 1. Định nghĩa State của Giỏ hàng
class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  // Getter tự động tính tổng tiền
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.total);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

// 2. Định nghĩa Controller
@Riverpod(keepAlive: true) // Giữ giỏ hàng không bị mất khi chuyển màn hình
class CartController extends _$CartController {
  @override
  CartState build() {
    // 🔥 Lắng nghe SignalR: Nếu kho thay đổi -> Cập nhật giỏ hàng ngay lập tức
    _listenToStockUpdates();
    return CartState();
  }

  void _listenToStockUpdates() {
    // Lấy instance của SignalR Notifier
    // Nếu import đúng, biến signalRServiceProvider sẽ hết báo lỗi đỏ
    final signalR = ref.read(signalRServiceProvider.notifier);

    // Đăng ký lắng nghe sự kiện kho
    signalR.stockUpdateStream.listen((event) {
      final currentItems = state.items;

      // Tìm các sản phẩm trong giỏ có ID trùng với sản phẩm vừa cập nhật
      final indices = <int>[];
      for (var i = 0; i < currentItems.length; i++) {
        if (currentItems[i].productId == event.productId) {
          indices.add(i);
        }
      }

      if (indices.isNotEmpty) {
        final newItems = List<CartItem>.from(currentItems);
        bool stateChanged = false;

        for (final index in indices) {
          final item = newItems[index];

          // Logic: Nếu số lượng đang mua > tồn kho mới -> Giảm xuống bằng tồn kho
          int newQuantity = item.quantity;
          if (newQuantity > event.newQuantity) {
            newQuantity = event.newQuantity.toInt();
            print(
              "⚠️ Giỏ hàng: SP ${item.productName} tự động giảm còn $newQuantity",
            );
            stateChanged = true;
          }

          // Luôn cập nhật MaxStock mới nhất vào giỏ hàng
          if (item.maxStock != event.newQuantity) {
            final updatedItem = item.copyWith(
              maxStock: event.newQuantity,
              quantity: newQuantity,
            );

            // Nếu số lượng về 0 -> Xóa khỏi giỏ
            if (newQuantity <= 0) {
              newItems.removeAt(index);
              // Lưu ý: Logic remove trong vòng lặp có thể phức tạp, ở đây demo đơn giản
            } else {
              newItems[index] = updatedItem;
            }
            stateChanged = true;
          }
        }

        if (stateChanged) {
          state = state.copyWith(items: newItems);
        }
      }
    });
  }

  // --- LOGIC NGHIỆP VỤ ---

  // Thêm vào giỏ (Trả về String lỗi nếu có, null nếu thành công)
  String? addToCart(CartItem newItem) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere(
      (item) =>
          item.productId == newItem.productId && item.unitId == newItem.unitId,
    );

    if (index >= 0) {
      // Đã có -> Cộng dồn số lượng
      final item = items[index];
      final newQty = item.quantity + newItem.quantity;

      if (newQty > item.maxStock) {
        return "Kho chỉ còn ${item.maxStock.toInt()} ${item.unitName} (Bạn đã có ${item.quantity})";
      }

      items[index] = item.copyWith(quantity: newQty);
    } else {
      // Chưa có -> Thêm mới
      if (newItem.quantity > newItem.maxStock) {
        return "Kho không đủ hàng (Còn ${newItem.maxStock.toInt()})";
      }
      items.add(newItem);
    }

    state = state.copyWith(items: items);
    return null;
  }

  // Cập nhật số lượng (+ / -)
  String? updateQuantity(int productId, int unitId, int newQuantity) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere(
      (item) => item.productId == productId && item.unitId == unitId,
    );

    if (index == -1) return "Sản phẩm không tồn tại";

    final item = items[index];

    if (newQuantity <= 0) {
      items.removeAt(index); // Xóa nếu số lượng về 0
    } else {
      if (newQuantity > item.maxStock) {
        return "Quá tồn kho! Chỉ còn ${item.maxStock.toInt()}";
      }
      items[index] = item.copyWith(quantity: newQuantity);
    }

    state = state.copyWith(items: items);
    return null;
  }

  // Xóa hẳn sản phẩm
  void removeItem(int productId, int unitId) {
    final items = List<CartItem>.from(state.items);
    items.removeWhere(
      (item) => item.productId == productId && item.unitId == unitId,
    );
    state = state.copyWith(items: items);
  }

  // Xóa giỏ hàng
  void clearCart() {
    state = CartState();
  }
}
