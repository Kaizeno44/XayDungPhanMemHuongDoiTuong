import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'cart_provider.dart';
import 'models.dart';
import 'core/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  ProductUnit? _selectedUnit;
  int _quantity = 1;
  String _stockMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.product.productUnits.firstWhere(
      (unit) => unit.isBaseUnit,
      orElse: () => widget.product.productUnits.first,
    );
    _checkStock();
  }

  Future<void> _checkStock() async {
    if (_selectedUnit == null) return;

    try {
      final result = await _apiService.simpleCheckStock(
        widget.product.id,
        _selectedUnit!.id,
        _quantity.toDouble(),
      );
      setState(() {
        _stockMessage = result.message;
      });
    } catch (e) {
      setState(() {
        _stockMessage = 'Lỗi kiểm tra tồn kho: $e';
      });
    }
  }

  void _updateQuantity(int change) {
    setState(() {
      _quantity = (_quantity + change).clamp(
        1,
        999,
      ); // Giới hạn số lượng từ 1 đến 999
    });
    _checkStock();
  }

  void _addToCart() async {
    if (_selectedUnit == null) return;

    final stockResult = await _apiService.simpleCheckStock(
      widget.product.id,
      _selectedUnit!.id,
      _quantity.toDouble(),
    );

    if (!stockResult.isEnough) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(stockResult.message),
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
    );
    // ignore: use_build_context_synchronously
    Provider.of<CartProvider>(context, listen: false).addToCart(cartItem);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm $_quantity ${_selectedUnit!.unitName} ${widget.product.name} vào giỏ!',
        ),
        duration: const Duration(seconds: 1),
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
            // Product Image (Placeholder)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image:
                      widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    widget.product.imageUrl == null ||
                        widget.product.imageUrl!.isEmpty
                    ? Icon(Icons.image, size: 100, color: Colors.grey[400])
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
                      color: _stockMessage.contains('Đủ hàng')
                          ? Colors.green
                          : Colors.red,
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
