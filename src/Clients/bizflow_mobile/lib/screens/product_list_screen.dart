import 'package:bizflow_mobile/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

// --- IMPORTS CONTROLLER & PROVIDER ---
import 'package:bizflow_mobile/features/cart/cart_controller.dart';
import 'package:bizflow_mobile/features/products/product_list_controller.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';

// --- SCREENS ---
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

  // --- APP BAR ---
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Danh sách Sản phẩm'),
      centerTitle: true,
      backgroundColor: Colors.orange[800],
      foregroundColor: Colors.white,

      // Nút Đăng xuất
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
            await ref.read(authNotifierProvider.notifier).logout();
          }
        },
      ),

      actions: [_buildCartButton()],
    );
  }

  // --- NÚT GIỎ HÀNG ---
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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Thanh tìm kiếm
          Container(
            padding: const EdgeInsets.all(16), // Whitespace: 16px
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
                // --- XỬ LÝ EMPTY STATE (CẢI TIẾN) ---
                if (products.isEmpty) {
                  final isSearching = _searchController.text.isNotEmpty;
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon minh họa (Visual Hierarchy)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Thông báo chính
                          Text(
                            "Không tìm thấy sản phẩm",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Thông báo phụ
                          Text(
                            isSearching
                                ? "Không có kết quả nào phù hợp với \"${_searchController.text}\""
                                : "Danh sách sản phẩm hiện đang trống",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 24),

                          // CALL TO ACTION (Nút hành động)
                          if (isSearching)
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(
                                      productListControllerProvider.notifier,
                                    )
                                    .search('');
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("Xóa bộ lọc & Xem tất cả"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(productListControllerProvider.future),
                  child: ListView.builder(
                    itemCount: products.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, // Whitespace: 16px
                      vertical: 12,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const AiMicButton(),
    );
  }

  // --- ITEM SẢN PHẨM (TỐI ƯU UX) ---
  Widget _buildProductCard(Product product) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Logic xác định trạng thái
    final isOutOfStock = product.inventoryQuantity <= 0;

    // Màu sắc & Icon nhất quán
    final cardColor = isOutOfStock ? Colors.grey[100] : Colors.white;
    final placeholderBgColor = isOutOfStock
        ? Colors.grey[200]
        : Colors.orange.shade50;
    final placeholderIconColor = isOutOfStock
        ? Colors.grey
        : Colors.orange.shade300;
    const placeholderIcon = Icons.inventory_2_outlined;

    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16), // Whitespace
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
              // --- Ảnh sản phẩm ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64, // Tăng kích thước ảnh
                  height: 64,
                  color: placeholderBgColor,
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: placeholderIconColor,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            placeholderIcon,
                            color: placeholderIconColor,
                          ),
                        )
                      : Center(
                          child: Icon(
                            placeholderIcon,
                            color: placeholderIconColor,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // --- Thông tin chi tiết ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isOutOfStock ? Colors.grey[600] : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${currencyFormat.format(product.price)} / ${product.unitName}",
                      style: TextStyle(
                        color: isOutOfStock
                            ? Colors.grey[500]
                            : Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Badge trạng thái tồn kho
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
                    else
                      Text(
                        "Tồn kho: ${product.inventoryQuantity.toStringAsFixed(0)} ${product.unitName}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // --- Nút thêm vào giỏ (Fitts's Law: To hơn, dễ bấm hơn) ---
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: isOutOfStock
                        ? Colors.grey[300]
                        : Colors.orange[800],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.add, size: 28),
                  onPressed: isOutOfStock ? null : () => _addToCart(product),
                ),
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
