import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'cart_provider.dart';
import 'models.dart';
import 'core/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'screens/stock_import_screen.dart';
import 'providers/auth_provider.dart';
import 'core/service_locator.dart'; // [MỚI] Import ServiceLocator

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  // [ĐÃ SỬA] Xóa dòng khởi tạo ProductService bị lỗi ở đây

  ProductUnit? _selectedUnit;
  int _quantity = 1;
  String _stockMessage = '';
  double _currentInventory = 0;

  @override
  void initState() {
    super.initState();
    _currentInventory = widget.product.inventoryQuantity;
    _selectedUnit = widget.product.productUnits.firstWhere(
      (unit) => unit.isBaseUnit,
      orElse: () => widget.product.productUnits.first,
    );
    _checkStock();
  }

  Future<void> _refreshProductData() async {
    try {
      // [ĐÃ SỬA] Gọi qua Repository thay vì Service
      final updatedProduct = await ServiceLocator.productRepo.getProductById(
        widget.product.id,
      );

      if (mounted) {
        setState(() {
          _currentInventory = updatedProduct.inventoryQuantity;
        });
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật dữ liệu sản phẩm: $e");
    }
  }

  // ... (Các phần code còn lại giữ nguyên không đổi)
  Future<void> _checkStock() async {
    if (_selectedUnit == null) return;

    try {
      final result = await _apiService.simpleCheckStock(
        widget.product.id,
        _selectedUnit!.id,
        _quantity.toDouble(),
      );
      if (mounted) {
        setState(() {
          _stockMessage = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stockMessage = 'Lỗi kiểm tra tồn kho: $e';
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

    final stockResult = await _apiService.simpleCheckStock(
      widget.product.id,
      _selectedUnit!.id,
      _quantity.toDouble(),
    );

    if (!mounted) return;

    if (!stockResult.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(stockResult.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

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
      context,
      listen: false,
    ).addToCart(cartItem);

    if (errorMsg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm $_quantity ${_selectedUnit!.unitName} ${widget.product.name} vào giỏ!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.currentUser?.role != 'Owner') return const SizedBox();
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
