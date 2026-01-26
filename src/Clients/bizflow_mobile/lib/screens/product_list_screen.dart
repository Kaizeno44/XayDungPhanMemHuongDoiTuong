import 'package:bizflow_mobile/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';

// --- IMPORTS CONTROLLER & PROVIDER ---
import 'package:bizflow_mobile/features/cart/cart_controller.dart';
import 'package:bizflow_mobile/features/products/product_list_controller.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';

// --- SCREENS ---
// Đã xóa import StockImportHistoryScreen vì không dùng ở đây nữa
import 'package:bizflow_mobile/product_detail_screen.dart';
import 'package:bizflow_mobile/cart_screen.dart';
import 'package:bizflow_mobile/widgets/ai_mic_button.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC TÌM KIẾM ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(productListControllerProvider.notifier).search(query);
    });
  }

  // --- UI HELPER: Random màu sắc icon ---
  Map<String, dynamic> _getProductUI(int id) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
    ];
    final icons = [
      Icons.home_work,
      Icons.build,
      Icons.layers,
      Icons.construction,
    ];
    final random = Random(id);
    return {
      'color': colors[random.nextInt(colors.length)],
      'icon': icons[random.nextInt(icons.length)],
    };
  }

  // --- APP BAR (ĐÃ CHỈNH SỬA) ---
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Danh sách Sản phẩm'),
      centerTitle: true,
      // Đổi thành màu cam cho đồng bộ với App
      backgroundColor: Colors.orange[800],
      foregroundColor: Colors.white,

      // Nút Đăng xuất (Góc trái)
      leading: IconButton(
        icon: const Icon(Icons.logout),
        tooltip: "Đăng xuất",
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Đăng xuất"),
              content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Hủy"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    "Đồng ý",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            // Gọi hàm logout từ AuthNotifier
            await ref.read(authNotifierProvider.notifier).logout();
          }
        },
      ),

      actions: [
        // Chỉ giữ lại nút Giỏ hàng
        _buildCartButton(),
      ],
    );
  }

  // --- NÚT GIỎ HÀNG (Có Badge số lượng) ---
  Widget _buildCartButton() {
    final cartState = ref.watch(cartControllerProvider);
    final itemCount = cartState.items.length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          tooltip: "Giỏ hàng",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
        if (itemCount > 0)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$itemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // --- UI CHÍNH ---
  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productListControllerProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Colors.grey[50], // Nền sáng nhẹ
      body: Column(
        children: [
          // Thanh tìm kiếm
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên, mã sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(productListControllerProvider.notifier)
                              .search('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Danh sách sản phẩm
          Expanded(
            child: asyncProducts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text("Lỗi: ${err.toString().replaceAll('Exception:', '')}"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(productListControllerProvider),
                      child: const Text("Thử lại"),
                    ),
                  ],
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không tìm thấy sản phẩm nào",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(productListControllerProvider.future),
                  child: ListView.builder(
                    itemCount: products.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) =>
                        _buildProductCard(products[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Nút micro AI
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const AiMicButton(),
    );
  }

  // --- ITEM SẢN PHẨM ---
  Widget _buildProductCard(Product product) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final uiProps = _getProductUI(product.id);
    final isOutOfStock = product.inventoryQuantity <= 0;

    return Card(
      elevation: 2,
      color: isOutOfStock ? Colors.grey[200] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh sản phẩm (hoặc Icon giả lập)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 60,
                  height: 60,
                  color: (uiProps['color'] as Color).withOpacity(0.1),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Icon(uiProps['icon'], color: uiProps['color']),
                        )
                      : Icon(
                          uiProps['icon'],
                          color: uiProps['color'],
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Thông tin chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isOutOfStock ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${currencyFormat.format(product.price)} / ${product.unitName}",
                      style: TextStyle(
                        color: isOutOfStock ? Colors.grey : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    isOutOfStock
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "HẾT HÀNG",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            "Tồn kho: ${product.inventoryQuantity.toStringAsFixed(0)} ${product.unitName}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                  ],
                ),
              ),

              // Nút thêm vào giỏ hàng (+)
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? Colors.grey
                      : Colors.orange[800], // Màu cam cho nút thêm
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                onPressed: isOutOfStock ? null : () => _addToCart(product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC THÊM VÀO GIỎ ---
  void _addToCart(Product product) {
    if (product.inventoryQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã hết hàng!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartItem = CartItem(
      productId: product.id,
      productName: product.name,
      unitId: product.unitId,
      unitName: product.unitName,
      price: product.price,
      quantity: 1,
      maxStock: product.inventoryQuantity,
    );

    final result = ref
        .read(cartControllerProvider.notifier)
        .addToCart(cartItem);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${product.name} vào giỏ!'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
  }
}
