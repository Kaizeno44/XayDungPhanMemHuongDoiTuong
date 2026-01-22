import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'cart_provider.dart';
import 'models.dart';
import 'core/api_service.dart'; // Import ApiService mới
import 'core/service_locator.dart';
import 'screens/stock_import_screen.dart';
import 'providers/auth_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // [CẢI TIẾN] Không tự khởi tạo ApiService nữa, sẽ lấy từ Provider

  ProductUnit? _selectedUnit;
  int _quantity = 1;
  String _stockMessage = '';
  double _currentInventory = 0;

  @override
  void initState() {
    super.initState();
    _currentInventory = widget.product.inventoryQuantity;

    // Chọn đơn vị cơ bản mặc định
    _selectedUnit = widget.product.productUnits.firstWhere(
      (unit) => unit.isBaseUnit,
      orElse: () => widget.product.productUnits.first,
    );

    // Gọi kiểm tra tồn kho sau khi widget đã build xong để có context an toàn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStock();
    });
  }

  Future<void> _refreshProductData() async {
    try {
      final updatedProduct = await ServiceLocator.productRepo.getProductById(
        widget.product.id,
      );

      if (mounted) {
        setState(() {
          _currentInventory = updatedProduct.inventoryQuantity!;
        });
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật dữ liệu sản phẩm: $e");
    }
  }

  Future<void> _checkStock() async {
    if (_selectedUnit == null) return;
    if (!mounted) return;

    try {
      // [CẢI TIẾN] Lấy ApiService từ Provider
      final apiService = Provider.of<ApiService>(context, listen: false);

      // [SỬA LỖI] Gọi qua ProductService (Chopper) thay vì hàm thủ công cũ
      final response = await apiService.productService.checkStock({
        'requests': [
          {
            'productId': widget.product.id,
            'unitId': _selectedUnit!.id,
            'quantity': _quantity,
          },
        ],
      });

      if (mounted) {
        if (response.isSuccessful) {
          // Parse kết quả từ API (xử lý cả trường hợp trả về List hoặc Map)
          final dynamic body = response.body;
          SimpleCheckStockResult result;

          if (body is List && body.isNotEmpty) {
            result = SimpleCheckStockResult.fromJson(body.first);
          } else if (body is Map<String, dynamic>) {
            result = SimpleCheckStockResult.fromJson(body);
          } else {
            throw Exception("Dữ liệu tồn kho không hợp lệ");
          }

          setState(() {
            _stockMessage = result.message;
          });
        } else {
          setState(() {
            _stockMessage =
                'Không thể kiểm tra tồn kho (Lỗi ${response.statusCode})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stockMessage = 'Lỗi kết nối: $e';
        });
      }
    }
  }

  void _updateQuantity(int change) {
    setState(() {
      _quantity = (_quantity + change).clamp(1, 999);
    });
    _checkStock();
  }

  Future<void> _addToCart() async {
    if (_selectedUnit == null) return;
    if (!mounted) return;

    // 1. Kiểm tra tồn kho trước khi thêm
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final response = await apiService.productService.checkStock({
        'requests': [
          {
            'productId': widget.product.id,
            'unitId': _selectedUnit!.id,
            'quantity': _quantity,
          },
        ],
      });

      if (!response.isSuccessful) {
        _showSnackBar('Lỗi khi kiểm tra tồn kho', isError: true);
        return;
      }

      final dynamic body = response.body;
      SimpleCheckStockResult stockResult;

      if (body is List && body.isNotEmpty) {
        stockResult = SimpleCheckStockResult.fromJson(body.first);
      } else {
        stockResult = SimpleCheckStockResult.fromJson(body);
      }

      if (!stockResult.isAvailable) {
        _showSnackBar(stockResult.message, isError: true);
        return;
      }

      // 2. Thêm vào giỏ hàng
      final cartItem = CartItem(
        productId: widget.product.id,
        productName: widget.product.name,
        unitId: _selectedUnit!.id,
        unitName: _selectedUnit!.unitName,
        price: _selectedUnit!.price,
        quantity: _quantity,
        maxStock: widget.product.inventoryQuantity,
      );

      final errorMsg = Provider.of<CartProvider>(
        // ignore: use_build_context_synchronously
        context,
        listen: false,
      ).addToCart(cartItem);

      if (errorMsg == null) {
        _showSnackBar(
          'Đã thêm $_quantity ${_selectedUnit!.unitName} ${widget.product.name} vào giỏ!',
          isError: false,
        );
      } else {
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      _showSnackBar('Đã xảy ra lỗi: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[200],
                  child:
                      widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                        )
                      : Icon(Icons.image, size: 100, color: Colors.grey[400]),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // --- PHẦN QUẢN LÝ KHO (Chỉ hiện với Owner) ---
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                // Kiểm tra null an toàn hơn cho role
                final role = auth.currentUser?.role.toLowerCase() ?? '';
                if (role != 'owner' && role != 'admin') return const SizedBox();

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUẢN LÝ KHO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              'Hiện có: ${_currentInventory.toStringAsFixed(0)} ${widget.product.unitName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StockImportScreen(product: widget.product),
                            ),
                          );
                          if (result == true) {
                            _checkStock();
                            _refreshProductData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('NHẬP HÀNG'),
                      ),
                    ],
                  ),
                );
              },
            ),
            Text(
              widget.product.description ?? 'Không có mô tả.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đơn vị tính:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: widget.product.productUnits.map((unit) {
                return ChoiceChip(
                  label: Text(unit.unitName),
                  selected: _selectedUnit?.id == unit.id,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedUnit = unit;
                      });
                      _checkStock();
                    }
                  },
                  selectedColor: Colors.blue[100],
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _selectedUnit?.id == unit.id
                        ? Colors.blue[800]
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_selectedUnit != null)
              Text(
                'Giá: ${currencyFormat.format(_selectedUnit!.price)} / ${_selectedUnit!.unitName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Số lượng:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateQuantity(-1),
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateQuantity(1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _stockMessage,
                    style: TextStyle(
                      color:
                          _stockMessage.toLowerCase().contains('không') ||
                              _stockMessage.toLowerCase().contains('not')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text(
                  'Thêm vào giỏ hàng',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
