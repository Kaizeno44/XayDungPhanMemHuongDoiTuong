import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart'; // Import Product model

// Model cho 1 dòng nhập hàng
class ImportItem {
  final Product product;
  double quantity;
  double unitCost; // Giá vốn nhập vào

  ImportItem({required this.product, this.quantity = 1, this.unitCost = 0});

  // Tổng tiền dòng này = SL * Giá vốn
  double get total => quantity * unitCost;
}

// Controller quản lý danh sách nhập
class ImportNotifier extends Notifier<List<ImportItem>> {
  @override
  List<ImportItem> build() => [];

  // Thêm sản phẩm vào danh sách
  void addProduct(Product product) {
    // Kiểm tra nếu có rồi thì không thêm nữa
    final exists = state.any((item) => item.product.id == product.id);
    if (!exists) {
      // Mặc định lấy giá bán làm gợi ý giá nhập (hoặc để 0 tùy logic)
      state = [...state, ImportItem(product: product, unitCost: product.price)];
    }
  }

  // Xóa sản phẩm
  void removeProduct(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  // Cập nhật số lượng
  void updateQuantity(int productId, double qty) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          ImportItem(
            product: item.product,
            quantity: qty,
            unitCost: item.unitCost,
          )
        else
          item,
    ];
  }

  // Cập nhật giá nhập
  void updateCost(int productId, double cost) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          ImportItem(
            product: item.product,
            quantity: item.quantity,
            unitCost: cost,
          )
        else
          item,
    ];
  }

  // Xóa hết (khi nhập xong)
  void clear() {
    state = [];
  }
}

final importControllerProvider =
    NotifierProvider<ImportNotifier, List<ImportItem>>(ImportNotifier.new);
