import 'package:flutter/material.dart';
import 'models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.total);

  void addToCart(CartItem newItem) {
    final index = _items.indexWhere((i) => i.productId == newItem.productId && i.unitId == newItem.unitId);
    if (index >= 0) {
      _items[index].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
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