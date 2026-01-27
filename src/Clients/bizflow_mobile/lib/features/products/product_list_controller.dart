import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Imports Models & Core
import 'package:bizflow_mobile/models/product.dart';
import 'package:bizflow_mobile/core/result.dart';
import 'package:bizflow_mobile/models/events/stock_update_event.dart';

// Imports Providers & Services
import 'package:bizflow_mobile/providers/app_providers.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart'; // 👈 Thêm import này
import 'package:bizflow_mobile/services/signalr_service.dart';

part 'product_list_controller.g.dart';

@riverpod
class ProductListController extends _$ProductListController {
  StreamSubscription<StockUpdateEvent>? _subscription;

  @override
  Future<List<Product>> build() async {
    _setupSignalRListener();

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return _fetchProducts(keyword: '');
  }

  void _setupSignalRListener() {
    final signalRService = ref.read(signalRServiceProvider.notifier);

    _subscription = signalRService.stockUpdateStream.listen((event) {
      updateLocalStock(event.productId, event.newQuantity);
    });
  }

  Future<List<Product>> _fetchProducts({String? keyword}) async {
    final repo = ref.read(productRepositoryProvider);
    final auth = ref.read(authNotifierProvider);
    final storeId = auth.currentUser?.storeId;

    print("DEBUG: ProductListController._fetchProducts");
    print("   - StoreId from Auth: '$storeId'");
    print("   - Keyword: '$keyword'");

    final result = await repo.getProducts(
      keyword: keyword,
      storeId: storeId,
    );

    return switch (result) {
      Success(data: final list) => list,
      Failure(message: final msg) => throw Exception(msg),
    };
  }

  Future<void> search(String keyword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts(keyword: keyword));
  }

  // --- HÀM CẬP NHẬT TỒN KHO ---
  void updateLocalStock(int productId, double newQuantity) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final index = currentState.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    // Khai báo rõ kiểu List<Product> để tránh lỗi type
    final List<Product> updatedList = [
      for (final product in currentState)
        if (product.id == productId)
          // [SỬA LỖI TẠI ĐÂY]: Chỉ truyền 'newQuantity', xóa 'inventoryQuantity' đi
          product.copyWith(newQuantity: newQuantity)
        else
          product,
    ];

    state = AsyncValue.data(updatedList);
  }
}
