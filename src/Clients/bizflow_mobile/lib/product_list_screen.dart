import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Để random màu sắc cho đẹp

import 'cart_provider.dart';
import 'models.dart';
import 'cart_screen.dart';
import 'product_service.dart'; // Import service vừa tạo

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

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final fetchedProducts = await _productService.getProducts();
      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Hàm tiện ích để tạo icon/màu giả lập cho giao diện đẹp hơn
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
    final random = Random(id); // Dùng ID làm seed để màu cố định cho mỗi sp
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
        actions: [
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
                      textAlign: TextAlign.center,
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
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: (uiProps['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          uiProps['icon'],
                          color: uiProps['color'],
                          size: 30,
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "${currencyFormat.format(product.price)} / ${product.unitName}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                        onPressed: () {
                          // --- ĐÃ GỠ BỎ LOGIC CHẶN ID ---
                          // Bây giờ bạn có thể thêm bất kỳ sản phẩm nào

                          final cartItem = CartItem(
                            productId: product.id,
                            productName: product.name,
                            unitId: product.unitId,
                            unitName: product.unitName,
                            price: product.price,
                            quantity: 1,
                          );

                          Provider.of<CartProvider>(
                            context,
                            listen: false,
                          ).addToCart(cartItem);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm ${product.name} vào giỏ!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
