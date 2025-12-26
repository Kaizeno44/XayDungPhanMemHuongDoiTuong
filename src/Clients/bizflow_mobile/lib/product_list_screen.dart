import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'cart_provider.dart';
import 'models.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  // Dữ liệu giả lập (Đã đồng bộ với Database của bạn)
  final List<Map<String, dynamic>> products = const [
    {
      "id": 1, // Khớp với Database
      "name": "Xi măng Hà Tiên", // Khớp với Database
      "price": 80000.0, // Khớp với Database
      "unitId": 1, // Khớp với Database
      "unitName": "Bao",
      "icon": Icons.home_work,
      "color": Colors.grey,
    },
    // Các sản phẩm dưới đây CHƯA CÓ trong Database.
    // Nếu bấm mua sẽ bị lỗi 500. Tạm thời để hiển thị cho đẹp thôi.
    {
      "id": 999,
      "name": "Thép cuộn Hòa Phát (Chưa có trong kho)",
      "price": 18500.0,
      "unitId": 2,
      "unitName": "Kg",
      "icon": Icons.build,
      "color": Colors.blueGrey,
    },
  ];

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
                  builder: (_, cart, __) => cart.items.isEmpty
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
        child: ListView.builder(
          itemCount: products.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final product = products[index];
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
                    color: (product['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    product['icon'],
                    color: product['color'],
                    size: 30,
                  ),
                ),
                title: Text(
                  product['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "${currencyFormat.format(product['price'])} / ${product['unitName']}",
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
                    // QUAN TRỌNG: Chỉ cho phép thêm món ID=1 (Xi măng) để test thành công
                    if (product['id'] != 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Món này chưa có trong Database, vui lòng chọn Xi măng!',
                          ),
                        ),
                      );
                      return;
                    }

                    final cartItem = CartItem(
                      productId: product['id'], // ID là int (số 1)
                      productName: product['name'],
                      unitId: product['unitId'],
                      unitName: product['unitName'],
                      price: product['price'],
                      quantity: 1,
                    );
                    Provider.of<CartProvider>(
                      context,
                      listen: false,
                    ).addToCart(cartItem);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm ${product['name']} vào giỏ!'),
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
