import 'dart:async';
import 'dart:convert';

import 'package:bizflow_mobile/core/result.dart';
import 'package:bizflow_mobile/core/service_locator.dart';
import 'package:bizflow_mobile/models.dart';
import 'package:bizflow_mobile/models/events/stock_update_event.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';
import 'package:bizflow_mobile/services/signalr_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  // Service
  final _apiService = ServiceLocator.apiService;

  // Data State
  late Product _product;
  ProductUnit? _selectedUnit;
  int _quantity = 1;
  double _currentInventory = 0.0;

  // UI State
  String _stockMessage = '';
  bool _isLoading = false; // Trạng thái loading toàn màn hình khi lưu

  // Realtime
  StreamSubscription<StockUpdateEvent>? _signalRSubscription;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _currentInventory = (_product.inventoryQuantity ?? 0).toDouble();

    // Tự động chọn đơn vị cơ bản (hoặc đơn vị đầu tiên)
    if (_product.productUnits.isNotEmpty) {
      _selectedUnit = _product.productUnits.firstWhere(
        (unit) => unit.isBaseUnit,
        orElse: () => _product.productUnits.first,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStock();
      _listenToRealtimeUpdates();
    });
  }

  @override
  void dispose() {
    _signalRSubscription?.cancel();
    super.dispose();
  }

  // --- 1. LOGIC REAL-TIME (SIGNALR) ---
  void _listenToRealtimeUpdates() {
    final signalRService = ref.read(signalRServiceProvider.notifier);

    _signalRSubscription = signalRService.stockUpdateStream.listen((event) {
      if (event.productId == _product.id) {
        if (!mounted) return;

        setState(() {
          _currentInventory = event.newQuantity.toDouble();
        });

        // Kiểm tra lại khả năng đáp ứng tồn kho sau khi số lượng thay đổi
        _checkStock();

        // Hiển thị thông báo Toast/SnackBar nhỏ gọn hơn
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.sync, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kho cập nhật: ${event.newQuantity} ${_selectedUnit?.unitName ?? ""}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blueGrey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    });
  }

  // --- 2. LOGIC DỮ LIỆU ---

  /// Tải lại dữ liệu sản phẩm mới nhất từ Server
  Future<void> _refreshProductData() async {
    setState(() => _isLoading = true);
    try {
      final result = await ServiceLocator.productRepo.getProductById(
        _product.id,
      );

      if (!mounted) return;

      Product? updatedProduct;

      // [FIXED] Sửa lỗi undefined getter 'value'
      // Kiểm tra nếu là Success<Product> thì lấy .data
      if (result is Success<Product>) {
        updatedProduct = result.data;
      }
      // Fallback cho trường hợp trả về raw response (nếu repo trả về dynamic trong Failure hoặc case khác)
      else if (result is! Result && (result as dynamic).body != null) {
        updatedProduct = (result as dynamic).body as Product?;
      }

      if (updatedProduct != null) {
        setState(() {
          _product = updatedProduct!;
          _currentInventory = (updatedProduct.inventoryQuantity ?? 0)
              .toDouble();
        });
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật dữ liệu sản phẩm: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Kiểm tra tồn kho có đủ đáp ứng số lượng mua không
  Future<void> _checkStock() async {
    if (_selectedUnit == null || !mounted) return;

    // Reset message nếu quantity <= 0 (dù logic UI đã chặn)
    if (_quantity <= 0) {
      setState(() => _stockMessage = '');
      return;
    }

    try {
      final response = await _apiService.productService.checkStock({
        'requests': [
          {
            'productId': _product.id,
            'unitId': _selectedUnit!.id,
            'quantity': _quantity,
          },
        ],
      });

      if (!mounted) return;

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
        setState(() => _stockMessage = '');
      }
    } catch (e) {
      debugPrint("Lỗi check stock: $e");
      if (mounted) setState(() => _stockMessage = '');
    }
  }

  /// Cập nhật ảnh sản phẩm
  Future<void> _updateProductImage(String newImageUrl) async {
    setState(() => _isLoading = true);

    try {
      // Endpoint: /api/products/{id}
      final client = _apiService.productService.client;
      final url = Uri.parse('${client.baseUrl}/api/products/${_product.id}');

      // Tạo body request chuẩn
      final body = jsonEncode({
        "name": _product.name,
        "description": _product.description,
        "categoryId": _product.categoryId,
        "imageUrl": newImageUrl,
        "units": _product.productUnits.map((u) => u.toJson()).toList(),
        "sku": _product.sku, // Đảm bảo gửi đủ field required
      });

      final response = await client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Cập nhật UI ngay lập tức để user thấy phản hồi
        setState(() {
          _product = _product.copyWith(imageUrl: newImageUrl);
        });
        _showSnackBar("Đã cập nhật hình ảnh!", isError: false);

        // Gọi refresh để đồng bộ dữ liệu chuẩn từ server
        await _refreshProductData();
      } else {
        _showSnackBar(
          "Lỗi lưu ảnh (${response.statusCode}): ${response.body}",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Lỗi update ảnh: $e");
      _showSnackBar("Lỗi kết nối khi lưu ảnh", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. UI HELPERS ---

  void _updateQuantity(int change) {
    final newQuantity = _quantity + change;
    if (newQuantity < 1) return;

    setState(() {
      _quantity = newQuantity;
    });
    // Debounce check stock nếu cần, ở đây gọi trực tiếp cho đơn giản
    _checkStock();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUpdateImageDialog() {
    final TextEditingController urlController = TextEditingController(
      text: _product.imageUrl,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật hình ảnh"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập đường dẫn (URL) hình ảnh mới:"),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: "URL Hình ảnh",
                border: OutlineInputBorder(),
                hintText: "https://example.com/image.png",
                prefixIcon: Icon(Icons.link),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (urlController.text.trim().isNotEmpty) {
                _updateProductImage(urlController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
            ),
            child: const Text("Lưu thay đổi"),
          ),
        ],
      ),
    );
  }

  // --- 4. WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final authState = ref.watch(authNotifierProvider);
    final userRole = (authState.currentUser?.role ?? '').toLowerCase();
    final isOwnerOrAdmin = userRole == 'owner' || userRole == 'admin';

    // Tính tổng tiền
    final double unitPrice = _selectedUnit?.price ?? 0;
    final double totalPrice = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Chi tiết sản phẩm"),
        centerTitle: true,
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Bottom Bar (Hiển thị Tạm tính + Nút Mua)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tạm tính:",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      currencyFormat.format(totalPrice),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: ElevatedButton.icon(
                  onPressed: _currentInventory > 0
                      ? () {
                          // TODO: Thêm logic Add to Cart hoặc Submit Order tại đây
                          _showSnackBar("Đã thêm vào đơn hàng (Demo)");
                        }
                      : null, // Disable nếu hết hàng
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                  ),
                  label: Text(
                    _currentInventory > 0 ? "THÊM VÀO ĐƠN" : "HẾT HÀNG",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Ảnh sản phẩm
                _buildProductImageHeader(isOwnerOrAdmin),

                // 2. Thông tin chính (Tên, Giá, SKU)
                _buildProductInfo(currencyFormat),

                const SizedBox(height: 12),

                // 3. Khu vực Admin/Owner (Hiển thị tồn kho chi tiết)
                if (isOwnerOrAdmin) _buildAdminStockPanel(),

                const SizedBox(height: 12),

                // 4. Chọn đơn vị & Số lượng
                _buildPurchaseOptions(),

                const SizedBox(height: 12),

                // 5. Mô tả sản phẩm
                _buildDescription(),

                const SizedBox(height: 30), // Padding bottom for scroll
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildProductImageHeader(bool canEdit) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          color: Colors.white,
          child: _product.imageUrl != null && _product.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _product.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => _buildPlaceholderImage(),
                )
              : _buildPlaceholderImage(),
        ),
        if (canEdit)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: "Sửa hình ảnh",
                onPressed: _showUpdateImageDialog,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Text("Chưa có ảnh", style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildProductInfo(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedUnit != null)
            Text(
              currencyFormat.format(_selectedUnit!.price),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.orange[800],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStockStatusBadge(),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  "SKU: ${_product.sku}",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusBadge() {
    final isAvailable = _currentInventory > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isAvailable ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? "Còn hàng" : "Hết hàng",
            style: TextStyle(
              color: isAvailable ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStockPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warehouse, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Text(
                "QUẢN LÝ KHO (ADMIN)",
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tồn kho thực tế:",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                "${_currentInventory.toStringAsFixed(0)} ${_product.unitName}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tùy chọn mua hàng",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Đơn vị
          const Text(
            "Đơn vị tính:",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _product.productUnits.map((unit) {
              final isSelected = _selectedUnit?.id == unit.id;
              return ChoiceChip(
                label: Text(unit.unitName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedUnit = unit);
                    _checkStock();
                  }
                },
                selectedColor: Colors.orange[100],
                backgroundColor: Colors.grey[50],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange[900] : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.orange[800]! : Colors.grey[300]!,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Số lượng
          const Text(
            "Số lượng:",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuantityController(),
              const SizedBox(width: 16),
              // Thông báo stock message
              if (_stockMessage.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _stockMessage.toLowerCase().contains('không') ||
                              _stockMessage.toLowerCase().contains('not')
                          ? Colors.red[50]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _stockMessage,
                      style: TextStyle(
                        color:
                            _stockMessage.toLowerCase().contains('không') ||
                                _stockMessage.toLowerCase().contains('not')
                            ? Colors.red[700]
                            : Colors.green[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityController() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _updateQuantity(-1),
            icon: Icon(
              Icons.remove,
              size: 20,
              color: _quantity > 1 ? Colors.black87 : Colors.grey,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Container(
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide.none,
                vertical: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Text(
              '$_quantity',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => _updateQuantity(1),
            icon: const Icon(Icons.add, size: 20),
            color: Colors.orange[800],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mô tả sản phẩm",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _product.description?.isNotEmpty == true
                ? _product.description!
                : 'Sản phẩm này chưa có mô tả chi tiết.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
