import 'package:flutter/material.dart';
import 'models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // --- [PHẦN AI - Person D] ---
  Customer? _draftCustomer;
  String _paymentMethod = 'Cash';

  // --- GETTERS ---
  List<CartItem> get items => _items;
  Customer? get draftCustomer => _draftCustomer;
  String get paymentMethod => _paymentMethod;

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  // --- NHẬN THÔNG TIN TỪ AI BUTTON ---
  void setOrderInfoFromAI({String? name, String? phone, String? method}) {
    if (name != null) {
      _draftCustomer = Customer(
        id: "ai_temp",
        name: name,
        phone: phone ?? "",
      );
    }

    if (method != null) {
      if (method.toLowerCase().contains("nợ") ||
          method.toLowerCase().contains("debt")) {
        _paymentMethod = "Debt";
      } else {
        _paymentMethod = "Cash";
      }
    }
    notifyListeners();
  }

  // --- LOGIC GIỎ HÀNG (Person C - ĐÃ FIX) ---

  /// 1. THÊM SẢN PHẨM
  /// return null = thành công | return String = lỗi tồn kho
  String? addToCart(CartItem newItem) {
    final index = _items.indexWhere((item) =>
        item.productId == newItem.productId &&
        item.unitId == newItem.unitId);

    if (index >= 0) {
      final item = _items[index];
      final newQty = item.quantity + newItem.quantity;
      final stock = item.maxStock;

      // ✅ CHECK TỒN KHO
      if (stock != null && newQty > stock) {
        return "Không thể thêm! Kho chỉ còn ${stock.toInt()} ${item.unitName}";
      }

      item.quantity = newQty;
    } else {
      final stock = newItem.maxStock;

      // ✅ CHECK TỒN KHO
      if (stock != null && newItem.quantity > stock) {
        return "Không thể thêm! Kho chỉ còn ${stock.toInt()} ${newItem.unitName}";
      }

      _items.add(newItem);
    }

    notifyListeners();
    return null;
  }

  /// 2. CẬP NHẬT SỐ LƯỢNG (+ / - / nhập tay)
  String? updateQuantity(int productId, int unitId, int newQuantity) {
    final index = _items.indexWhere((item) =>
        item.productId == productId && item.unitId == unitId);

    if (index >= 0) {
      final item = _items[index];
      final stock = item.maxStock;

      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        // ✅ CHECK TỒN KHO
        if (stock != null && newQuantity > stock) {
          return "Quá số lượng tồn kho! (Max: ${stock.toInt()})";
        }
        item.quantity = newQuantity;
      }

      notifyListeners();
      return null;
    }

    return "Không tìm thấy sản phẩm trong giỏ";
  }

  /// 3. XÓA 1 SẢN PHẨM
  void removeItem(int productId, int unitId) {
    _items.removeWhere((item) =>
        item.productId == productId && item.unitId == unitId);
    notifyListeners();
  }

  /// 4. CLEAR GIỎ + RESET THÔNG TIN AI
  void clearCart() {
    _items.clear();
    _draftCustomer = null;
    _paymentMethod = 'Cash';
    notifyListeners();
  }
}
