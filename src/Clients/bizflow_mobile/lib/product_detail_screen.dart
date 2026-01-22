import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider; // Alias
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

// --- IMPORTS ---
import 'package:bizflow_mobile/models.dart';
// [MỚI] Import Controller giỏ hàng mới
import 'package:bizflow_mobile/features/cart/cart_controller.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';
import 'package:bizflow_mobile/core/api_service.dart';
import 'package:bizflow_mobile/core/service_locator.dart';
import 'package:bizflow_mobile/screens/stock_import_screen.dart';

// Import SignalR
import 'package:bizflow_mobile/services/signalr_service.dart';
import 'package:bizflow_mobile/models/events/stock_update_event.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final ApiService _apiService = ServiceLocator.apiService;

  ProductUnit? _selectedUnit;
  int _quantity = 1;
  String _stockMessage = '';
  double _currentInventory = 0;
  StreamSubscription<StockUpdateEvent>? _signalRSubscription;

  @override
  void initState() {
    super.initState();
    _currentInventory = widget.product.inventoryQuantity;

    _selectedUnit = widget.product.productUnits.firstWhere(
      (unit) => unit.isBaseUnit,
      orElse: () => widget.product.productUnits.first,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStock();
      _listenToRealtimeUpdates();
    });
  }

  void _listenToRealtimeUpdates() {
    final signalRService = ref.read(signalRServiceProvider.notifier);

    _signalRSubscription = signalRService.stockUpdateStream.listen((event) {
      if (event.productId == widget.product.id) {
        if (mounted) {
          setState(() {
            _currentInventory = event.newQuantity;
          });
          _checkStock();

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Tồn kho vừa cập nhật: ${event.newQuantity}'),
              backgroundColor: Colors.orange[800],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _signalRSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshProductData() async {
    try {
      final updatedProduct = await ServiceLocator.productRepo.getProductById(
        widget.product.id,
      );

      if (mounted) {
        setState(() {
          _currentInventory = updatedProduct.inventoryQuantity ?? 0.0;
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
      final response = await _apiService.productService.checkStock({
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
          final dynamic body = response.body;
          SimpleCheckStockResult result;

          if (body is List && body.isNotEmpty) {
            result = SimpleCheckStockResult.fromJson(body.first);
          } else if (body is Map<String, dynamic>) {
            result = SimpleCheckStockResult.fromJson(body);
          } else {
            setState(() => _stockMessage = '');
            return;
          }

          setState(() {
            _stockMessage = result.message;
          });
        } else {
          setState(() {
            _stockMessage = 'Lỗi kiểm tra kho (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _stockMessage = '');
    }
  }

  void _updateQuantity(int change) {
    setState(() {
      _quantity = (_quantity + change).clamp(1, 999);
    });
    _checkStock();
  }

  // 🔥 [CẬP NHẬT QUAN TRỌNG] Sửa logic thêm vào giỏ hàng
  Future<void> _addToCart() async {
    if (_selectedUnit == null) return;
    if (!mounted) return;

    if (_currentInventory <= 0) {
      _showSnackBar('Sản phẩm đã hết hàng!', isError: true);
      return;
    }

    try {
      // 1. Kiểm tra tồn kho phía Server trước cho chắc chắn
      final response = await _apiService.productService.checkStock({
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

      // 2. Tạo CartItem
      final cartItem = CartItem(
        productId: widget.product.id,
        productName: widget.product.name,
        unitId: _selectedUnit!.id,
        unitName: _selectedUnit!.unitName,
        price: _selectedUnit!.price,
        quantity: _quantity,
        maxStock: _currentInventory,
      );

      // 3. [SỬA LỖI] Dùng Riverpod CartController thay vì Provider cũ
      // Gọi .notifier để truy cập các hàm logic (addToCart)
      final errorMsg = ref
          .read(cartControllerProvider.notifier)
          .addToCart(cartItem);

      if (errorMsg == null) {
        _showSnackBar(
          'Đã thêm $_quantity ${_selectedUnit!.unitName} vào giỏ!',
          isError: false,
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Quay lại màn hình trước
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
        behavior: SnackBarBehavior.floating,
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
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[200],
                  child:
                      widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.image, size: 100, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Phần dành cho Owner/Admin
            provider.Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final role = (auth.currentUser?.role ?? '').toLowerCase();
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
                              'QUẢN LÝ KHO (REAL-TIME)',
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
                                fontSize: 16,
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
            const Divider(),

            const Text(
              "Đơn vị tính:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.product.productUnits.map((unit) {
                final isSelected = _selectedUnit?.id == unit.id;
                return ChoiceChip(
                  label: Text(unit.unitName),
                  selected: isSelected,
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
                    color: isSelected ? Colors.blue[800] : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_selectedUnit != null)
              Text(
                'Giá: ${currencyFormat.format(_selectedUnit!.price)} / ${_selectedUnit!.unitName}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
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
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _updateQuantity(-1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateQuantity(1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _stockMessage,
                    style: TextStyle(
                      color:
                          _stockMessage.toLowerCase().contains('không') ||
                              _stockMessage.toLowerCase().contains('not') ||
                              _stockMessage.contains('Lỗi')
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_currentInventory > 0) ? _addToCart : null,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                  ),
                  label: Text(
                    _currentInventory > 0 ? 'Thêm vào giỏ hàng' : 'HẾT HÀNG',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentInventory > 0
                        ? Colors.blue[800]
                        : Colors.grey,
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
            ),
          ],
        ),
      ),
    );
  }
}
