import 'package:flutter/material.dart';
import '../models.dart';
import '../product_service.dart';

class StockImportScreen extends StatefulWidget {
  // 👇 QUAN TRỌNG: Dấu ? nghĩa là có thể null.
  // Không có 'required' nghĩa là truyền cũng được, không truyền cũng được.
  final Product? product;

  const StockImportScreen({super.key, this.product});

  @override
  State<StockImportScreen> createState() => _StockImportScreenState();
}

class _StockImportScreenState extends State<StockImportScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _displayProducts = [];

  final Map<int, double> _importCart = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;

          // 👇 LOGIC XỬ LÝ 2 TRƯỜNG HỢP:
          if (widget.product != null) {
            // TRƯỜNG HỢP 1: Vào từ trang Chi tiết sản phẩm
            // -> Chỉ hiển thị đúng sản phẩm đó
            _displayProducts = products
                .where((p) => p.id == widget.product!.id)
                .toList();
            _searchController.text = widget.product!.name; // Điền sẵn tên

            // Tự động bật popup nhập số lượng luôn cho tiện
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final currentProduct = products.firstWhere(
                (p) => p.id == widget.product!.id,
                orElse: () => widget.product!,
              );
              _showInputQuantityDialog(currentProduct);
            });
          } else {
            // TRƯỜNG HỢP 2: Vào từ Dashboard
            // -> Hiển thị tất cả sản phẩm
            _displayProducts = products;
          }
        });
      }
    } catch (e) {
      print("Lỗi tải sp: $e");
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayProducts = _allProducts;
      } else {
        _displayProducts = _allProducts
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showInputQuantityDialog(Product product) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nhập thêm: ${product.name}"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Số lượng nhập",
            hintText: "VD: 100",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text);
              if (qty != null && qty > 0) {
                setState(() {
                  _importCart[product.id] =
                      (_importCart[product.id] ?? 0) + qty;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Đã thêm $qty ${product.unitName} vào phiếu"),
                  ),
                );
              }
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitImport() async {
    if (_importCart.isEmpty) return;

    setState(() => _isLoading = true);

    final itemsToSend = _importCart.entries
        .map((e) => {"productId": e.key, "quantity": e.value, "importPrice": 0})
        .toList();

    try {
      await _productService.importStock(itemsToSend, "Nhập từ Mobile App");

      if (!mounted) return;

      setState(() {
        _importCart.clear();
        _isLoading = false;
      });

      // Reload lại để cập nhật số tồn kho hiển thị ngay lập tức
      await _loadProducts();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Thành công"),
          content: const Text("Đã nhập kho xong!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng Dialog thông báo

                // Nếu đang ở chế độ nhập 1 sản phẩm (từ trang chi tiết) -> Quay về trang trước luôn
                if (widget.product != null) {
                  Navigator.pop(
                    context,
                    true,
                  ); // Trả về true để trang trước biết mà refresh
                }
              },
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nhập kho"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_importCart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitImport,
                icon: const Icon(Icons.save),
                label: Text("Lưu (${_importCart.length})"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: const InputDecoration(
                hintText: "Tìm vật liệu...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _displayProducts.length,
              itemBuilder: (context, index) {
                final product = _displayProducts[index];
                final qtyInCart = _importCart[product.id] ?? 0;

                return Card(
                  color: qtyInCart > 0 ? Colors.blue[50] : Colors.white,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Kho hiện tại: ${product.inventoryQuantity} ${product.unitName}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (qtyInCart > 0)
                          Text(
                            "+$qtyInCart ",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue,
                            size: 28,
                          ),
                          onPressed: () => _showInputQuantityDialog(product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
