import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:async';
import 'package:signalr_core/signalr_core.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'cart_provider.dart';
import 'models.dart';
import 'cart_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/stock_import_history_screen.dart';
import 'core/config/api_config.dart';
import 'product_detail_screen.dart';
import 'widgets/ai_mic_button.dart';
import 'core/service_locator.dart'; // Import ServiceLocator

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // [ĐÃ SỬA] Đã xóa dòng: final ProductService _productService = ProductService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  HubConnection? _hubConnection;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _initSignalR();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _hubConnection?.stop();
    super.dispose();
  }

  // --- 1. SIGNALR CONFIGURATION ---
  Future<void> _initSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(ApiConfig.productHub, HttpConnectionOptions())
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose((error) => debugPrint("Connection Closed: $error"));

    _hubConnection?.on("ReceiveStockUpdate", (arguments) {
      try {
        if (arguments == null || arguments.length < 2) return;

        final String strId = arguments[0].toString();
        final String strQty = arguments[1].toString();

        final int productId = int.parse(strId);
        final double newQuantity = double.parse(strQty);

        if (!mounted) return;

        setState(() {
          final index = products.indexWhere((p) => p.id == productId);
          if (index != -1) {
            products[index] = products[index].copyWith(
              inventoryQuantity: newQuantity,
            );
          }
        });
      } catch (e) {
        debugPrint("SignalR Error: $e");
      }
    });

    try {
      await _hubConnection?.start();
      debugPrint("✅ SignalR Connected!");
    } catch (e) {
      debugPrint("Error starting SignalR: $e");
    }
  }

  // --- 2. DATA FETCHING (QUAN TRỌNG NHẤT) ---
  Future<void> _fetchProducts({String keyword = ''}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // [ĐÃ SỬA] Gọi qua Repository thay vì Service
      // Repository trả về List<Product> chuẩn, khớp với biến 'products'
      final fetchedProducts = await ServiceLocator.productRepo.getProducts(
        keyword: keyword,
      );

      if (!mounted) return;

      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchProducts(keyword: query);
    });
  }

  // --- 3. HELPER UI ---
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

  // --- 4. APP BAR ---
  AppBar _buildAppBar(BuildContext context) {
    final bool canPop = Navigator.canPop(context);

    return AppBar(
      title: const Text('Kho VLXD'),
      centerTitle: true,
      backgroundColor: Colors.blue[800],
      foregroundColor: Colors.white,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Quay lại Dashboard',
              onPressed: () => Navigator.pop(context),
            )
          : IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
      actions: [
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            final role = (auth.currentUser?.role ?? '').toLowerCase();
            if (role != 'owner' && role != 'admin') return const SizedBox();

            return IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Lịch sử nhập kho',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StockImportHistoryScreen(),
                  ),
                );
              },
            );
          },
        ),
        _buildCartButton(),
      ],
    );
  }

  Widget _buildCartButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
        Positioned(
          right: 5,
          top: 5,
          child: Consumer<CartProvider>(
            builder: (_, cart, _) => cart.items.isEmpty
                ? const SizedBox()
                : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // --- 5. MAIN BODY ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm vật liệu...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchProducts(keyword: '');
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
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: RefreshIndicator(
                onRefresh: () =>
                    _fetchProducts(keyword: _searchController.text),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const AiMicButton(),
    );
  }

  Widget _buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 10),
            Text(
              "Lỗi: $errorMessage",
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _fetchProducts(keyword: _searchController.text),
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Không tìm thấy sản phẩm nào",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

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
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? Colors.grey
                      : Colors.blue[800],
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

    final result = Provider.of<CartProvider>(
      context,
      listen: false,
    ).addToCart(cartItem);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${product.name} vào giỏ!'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
  }
}
