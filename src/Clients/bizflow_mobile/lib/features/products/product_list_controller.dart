import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:bizflow_mobile/models/product.dart';
import 'package:bizflow_mobile/core/result.dart';
import 'package:bizflow_mobile/providers/app_providers.dart';

// [SỬA 1] Kiểm tra lại đường dẫn import.
// Nếu bạn để file trong lib/services/ thì dùng dòng dưới:
import 'package:bizflow_mobile/services/signalr_service.dart';
// Nếu bạn để trong lib/core/services/ thì giữ dòng dưới (nhưng máy báo lỗi file không tồn tại):
// import 'package:bizflow_mobile/core/services/signalr_service.dart';

import 'package:bizflow_mobile/models/events/stock_update_event.dart';

part 'product_list_controller.g.dart';

@riverpod
class ProductListController extends _$ProductListController {
  @override
  Future<List<Product>> build() async {
    // 1. Lấy instance của SignalR Notifier
    final signalRService = ref.read(signalRServiceProvider.notifier);

    // 2. Đăng ký lắng nghe Stream
    final subscription = signalRService.stockUpdateStream.listen((event) {
      _handleStockUpdate(event);
    });

    // 3. Hủy đăng ký khi Controller bị hủy
    ref.onDispose(() {
      subscription.cancel();
    });

    return _fetchProducts(keyword: '');
  }

  void _handleStockUpdate(StockUpdateEvent event) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final index = currentState.indexWhere((p) => p.id == event.productId);
    if (index == -1) return;

    final updatedList = List<Product>.from(currentState);
    final oldProduct = updatedList[index];

    // Tạo Inventory mới
    final newInventory = oldProduct.inventory?.copyWith(
      quantity: event.newQuantity,
    );

    if (newInventory != null) {
      // [SỬA 2] Truyền thêm inventoryQuantity để fix lỗi "missing required argument"
      updatedList[index] = oldProduct.copyWith(
        inventory: newInventory,
        // Dù logic mới dùng getter, nhưng copyWith cũ vẫn đòi tham số này
        inventoryQuantity: event.newQuantity,
      );

      state = AsyncValue.data(updatedList);
    }
  }

  Future<List<Product>> _fetchProducts({String? keyword}) async {
    final repo = ref.read(productRepositoryProvider);
    final result = await repo.getProducts(keyword: keyword);
    return switch (result) {
      Success(data: final list) => list,
      Failure(message: final msg) => throw Exception(msg),
    };
  }

  Future<void> search(String keyword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts(keyword: keyword));
  }

  void updateLocalStock(int productId, double newQuantity) {}
}
