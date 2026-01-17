// lib/cart_provider.dart
import 'package:flutter/material.dart';
import 'models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.total);

  // 👇 Trả về String? (null = thành công, String = lỗi)
  String? addToCart(CartItem newItem) {
    // 1. Check nếu thêm mới mà đã vượt quá kho ngay từ đầu
    if (newItem.quantity > newItem.maxStock) {
      return "Không đủ hàng! Kho chỉ còn ${newItem.maxStock.toInt()}";
    }

    final index = _items.indexWhere(
      (i) => i.productId == newItem.productId && i.unitId == newItem.unitId,
    );

    if (index >= 0) {
      // 2. Check khi cộng dồn số lượng cũ + mới
      final newTotal = _items[index].quantity + newItem.quantity;
      if (newTotal > _items[index].maxStock) {
        return "Không thể thêm! Tổng sẽ vượt quá kho (${_items[index].maxStock.toInt()})";
      }
      _items[index].quantity = newTotal;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
    return null; // Thành công
  }

  // 👇 Trả về String? để báo lỗi cho UI
  String? updateQuantity(int productId, int unitId, int newQuantity) {
    final index = _items.indexWhere(
      (i) => i.productId == productId && i.unitId == unitId,
    );
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        // 3. Check tồn kho khi bấm nút + hoặc nhập số
        if (newQuantity > _items[index].maxStock) {
          return "Quá số lượng tồn kho! (Max: ${_items[index].maxStock.toInt()})";
        }
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
    return null; // Thành công
  }

  void removeItem(int productId, int unitId) {
    _items.removeWhere((i) => i.productId == productId && i.unitId == unitId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
