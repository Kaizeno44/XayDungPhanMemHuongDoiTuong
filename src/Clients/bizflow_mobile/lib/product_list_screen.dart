// lib/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:signalr_core/signalr_core.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'cart_provider.dart';
import 'models.dart';
import 'cart_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/stock_import_history_screen.dart';
import 'product_service.dart';
import 'core/config/api_config.dart';
import 'product_detail_screen.dart';
import 'widgets/ai_mic_button.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  late HubConnection _hubConnection;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _initSignalR();
  }

  @override
  void dispose() {
    _hubConnection.stop();
    super.dispose();
  }

  Future<void> _initSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(ApiConfig.productHub, HttpConnectionOptions())
        .build();

    _hubConnection.onclose((error) => debugPrint("Connection Closed: $error"));

    _hubConnection.on("ReceiveStockUpdate", (arguments) {
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
      await _hubConnection.start();
    } catch (e) {
      debugPrint("Error starting SignalR: $e");
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetchedProducts = await _productService.getProducts();
      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho VLXD'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await Provider.of<AuthProvider>(context, listen: false).logout();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
        ),
        actions: [
          // Nút Lịch sử nhập kho (Chỉ hiện cho Owner)
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.currentUser?.role != 'Owner') return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Lịch sử nhập kho',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StockImportHistoryScreen()),
                  );
                },
              );
            },
          ),
          Stack(
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
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
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
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Lỗi: $errorMessage",
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchProducts,
                      child: const Text("Thử lại"),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: products.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final uiProps = _getProductUI(product.id);

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: (uiProps['color'] as Color).withOpacity(0.1),
                          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Icon(
                                    uiProps['icon'],
                                    color: uiProps['color'],
                                    size: 30,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    uiProps['icon'],
                                    color: uiProps['color'],
                                    size: 30,
                                  ),
                                )
                              : Icon(
                                  uiProps['icon'],
                                  color: uiProps['color'],
                                  size: 30,
                                ),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${currencyFormat.format(product.price)} / ${product.unitName}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Tồn kho: ${product.inventoryQuantity.toStringAsFixed(0)} ${product.unitName}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                        onPressed: () {
                          // 👇 Logic kiểm tra tồn kho tại nút bấm
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

                          // Gọi Provider và nhận về kết quả
                          final result = Provider.of<CartProvider>(
                            context,
                            listen: false,
                          ).addToCart(cartItem);

                          if (result == null) {
                            // Thành công
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã thêm ${product.name} vào giỏ!',
                                ),
                                duration: const Duration(milliseconds: 800),
                              ),
                            );
                          } else {
                            // Thất bại (Lỗi tồn kho)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const AiMicButton(),
    );
  }
}
