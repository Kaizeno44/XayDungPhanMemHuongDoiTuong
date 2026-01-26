import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'features/cart/cart_controller.dart';
import 'models.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const String currentStoreId = "3fa85f64-5717-4562-b3fc-2c963f66afa6";

  void _showQuantityDialog(BuildContext context, WidgetRef ref, CartItem item) {
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nhập số lượng (Kho: ${item.maxStock.toInt()})"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Số lượng",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text);
              if (newQty != null) {
                final error = ref
                    .read(cartControllerProvider.notifier)
                    .updateQuantity(item.productId, item.unitId, newQty);

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final cartItems = cartState.items;
    final totalAmount = cartState.totalAmount;

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // [ĐỒNG BỘ MÀU] Lấy màu từ Theme chung (main.dart)
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng"),
        // [ĐỒNG BỘ MÀU] Xóa backgroundColor cứng (Colors.blue[800]),
        // nó sẽ tự nhận màu Orange[800] từ main.dart
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = cartItems[i];
                      // Truyền colorScheme xuống
                      return _buildCartItem(
                        context,
                        ref,
                        item,
                        currencyFormat,
                        colorScheme,
                      );
                    },
                  ),
                ),
                _buildFooter(context, totalAmount, currencyFormat, colorScheme),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Giỏ hàng đang trống",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
    NumberFormat fmt,
    ColorScheme colorScheme, // [MỚI] Nhận colorScheme
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng 1: Tên sản phẩm + Nút xóa
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    ref
                        .read(cartControllerProvider.notifier)
                        .removeItem(item.productId, item.unitId);
                  },
                ),
              ],
            ),

            // Hàng 2: Giá & Tồn kho
            Row(
              children: [
                Text(
                  "${fmt.format(item.price)} / ${item.unitName}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // Có thể giữ màu cam cho Badge cảnh báo kho,
                    // hoặc đổi theo colorScheme.secondaryContainer nếu muốn
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    "Kho: ${item.maxStock.toInt()}",
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hàng 3: Bộ tăng giảm số lượng & Tổng tiền item
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(
                                item.productId,
                                item.unitId,
                                item.quantity - 1,
                              );
                        },
                      ),
                      InkWell(
                        onTap: () => _showQuantityDialog(context, ref, item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: Colors.grey.shade50,
                          child: Text(
                            "${item.quantity}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () {
                          final error = ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(
                                item.productId,
                                item.unitId,
                                item.quantity + 1,
                              );
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  fmt.format(item.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    // [ĐỒNG BỘ MÀU] Đổi Colors.blue -> colorScheme.primary
                    color: colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    double totalAmount,
    NumberFormat fmt,
    ColorScheme colorScheme, // [MỚI] Nhận colorScheme
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tổng cộng:",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  fmt.format(totalAmount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    // [ĐỒNG BỘ MÀU] Dùng màu Primary thay vì Red để đồng bộ app
                    // Hoặc giữ Red nếu muốn nhấn mạnh số tiền phải trả
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CheckoutScreen(
                        storeId: CartScreen.currentStoreId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  // [ĐỒNG BỘ MÀU]
                  // Xóa backgroundColor cứng.
                  // Main.dart đã set elevatedButtonTheme backgroundColor = primaryDark
                  // Nếu muốn chắc chắn: backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "TIẾN HÀNH THANH TOÁN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
