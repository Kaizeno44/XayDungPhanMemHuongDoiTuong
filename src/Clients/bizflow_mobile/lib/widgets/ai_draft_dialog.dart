import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../features/cart/cart_controller.dart';
import '../providers/app_providers.dart'; // Để gọi productRepositoryProvider
import '../core/result.dart'; // Để check kết quả Success/Failure
import '../models/product.dart'; // Để dùng model Product

class AiDraftDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const AiDraftDialog({super.key, required this.data});

  @override
  ConsumerState<AiDraftDialog> createState() => _AiDraftDialogState();
}

class _AiDraftDialogState extends ConsumerState<AiDraftDialog>{
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _paymentMethod = 'Cash';

  // Danh sách tạm thời để chỉnh sửa
  final List<CartItem> _draftItems = [];

  // Quản lý controller cho từng ô nhập số lượng (Key là productId)
  final Map<int, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _initData();
    
    // 🔥 MỚI THÊM: Gọi hàm lấy tồn kho thật ngay sau khi init xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRealStock();
    });
  }

  void _initData() {
    // 1. Fill thông tin khách
    _nameController = TextEditingController(
      text: widget.data['customer_name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.data['customer_phone'] ?? '',
    );

    // 2. Fill phương thức thanh toán
    String method = widget.data['payment_method'] ?? 'Cash';
    if (method.toLowerCase().contains('nợ') ||
        method.toLowerCase().contains('debt')) {
      _paymentMethod = 'Debt';
    }

    // 3. Parse items từ JSON
    final itemsJson = widget.data['items'] as List? ?? [];
    for (var item in itemsJson) {
      if (item['product_id'] != null) {
        final productId = item['product_id'];
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

        // Tạo CartItem
        _draftItems.add(
          CartItem(
            productId: productId,
            productName: item['product_name'] ?? 'Sản phẩm',
            unitId: 1, // Logic tạm
            unitName: item['unit'] ?? 'ĐVT',
            price: (item['price'] as num?)?.toDouble() ?? 0,
            quantity: quantity,
            maxStock: 99,
          ),
        );

        // Tạo Controller cho ô nhập liệu của sản phẩm này
        _qtyControllers[productId] = TextEditingController(
          text: quantity.toString(),
        );
      }
    }
  }

  // 🔥 MỚI THÊM: Hàm này sẽ chạy ngầm để cập nhật maxStock từ API
  Future<void> _fetchRealStock() async {
    // 1. Lấy repo từ Riverpod
    final productRepo = ref.read(productRepositoryProvider);

    // 2. Duyệt qua từng sản phẩm trong danh sách nháp
    for (var item in _draftItems) {
      // Gọi API lấy chi tiết sản phẩm (chứa thông tin inventory mới nhất)
      final result = await productRepo.getProductById(item.productId);

      if (result is Success<Product>) {
        final product = result.data;
        
        // Kiểm tra mounted để tránh lỗi gọi setState khi dialog đã đóng
        if (mounted) {
          setState(() {
            // Cập nhật maxStock thật
            item.maxStock = product.inventoryQuantity;

            // Logic phụ: Nếu số lượng khách đặt > tồn kho -> Tự giảm xuống bằng tồn kho
            if (item.quantity > item.maxStock) {
              item.quantity = item.maxStock.toInt();
              // Cập nhật lại cả ô nhập liệu hiển thị trên UI
              _qtyControllers[item.productId]?.text = item.quantity.toString();
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    // Dispose hết các controller con
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Hàm xóa sản phẩm
  void _removeItem(CartItem item) {
    setState(() {
      _draftItems.remove(item);
      // Xóa controller tương ứng để giải phóng bộ nhớ (không bắt buộc nhưng tốt)
      _qtyControllers[item.productId]?.dispose();
      _qtyControllers.remove(item.productId);
    });
  }

  // Hàm cập nhật số lượng từ nút +/-
  // Hàm cập nhật số lượng từ nút +/-
  void _updateQuantity(CartItem item, int change) {
    setState(() {
      final newQty = item.quantity + change;
      
      // Kiểm tra cận dưới (>0)
      if (newQty > 0) {
        // Kiểm tra cận trên (<= maxStock)
        if (newQty <= item.maxStock) {
          item.quantity = newQty;
          _qtyControllers[item.productId]?.text = newQty.toString();
        } else {
          // Nếu vượt quá -> Hiện thông báo nhỏ
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ Chỉ còn ${item.maxStock.toInt()} sản phẩm trong kho!"),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  // Hàm xử lý khi gõ phím vào ô số lượng
  void _onTypeQuantity(CartItem item, String value) {
    final newQty = int.tryParse(value);
    if (newQty != null) {
      if (newQty > item.maxStock) {
        // Nếu nhập quá tồn kho -> Gán về maxStock
        item.quantity = item.maxStock.toInt();
        
        // Cập nhật lại text trong ô nhập để người dùng thấy số đã bị sửa
        // Dùng addPostFrameCallback để tránh lỗi conflict khi đang gõ
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _qtyControllers[item.productId]?.text = item.quantity.toString();
            // Di chuyển con trỏ về cuối dòng
            _qtyControllers[item.productId]?.selection = TextSelection.fromPosition(
              TextPosition(offset: item.quantity.toString().length),
            );
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("⚠️ Đã điều chỉnh về tối đa ${item.maxStock.toInt()}!"))
        );
      } else if (newQty > 0) {
        // Nếu hợp lệ
        item.quantity = newQty;
      }
    }
  }

  void _confirmOrder() {
    final cartController = ref.read(cartControllerProvider.notifier);

    int count = 0;
    for (var item in _draftItems) {
      if (item.quantity > 0) {
        // Gọi hàm addToCart đã có sẵn trong cart_controller.dart
        final error = cartController.addToCart(item); 
        if (error == null) {
          count++;
        }
      }
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Đã thêm $count sản phẩm vào giỏ hàng!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text("Duyệt đơn hàng AI"),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FORM KHÁCH HÀNG ---
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Tên khách hàng",
                  prefixIcon: Icon(Icons.person),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Số điện thoại",
                  prefixIcon: Icon(Icons.phone),
                  isDense: true,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: "Thanh toán",
                  isDense: true,
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text("Tiền mặt")),
                  DropdownMenuItem(value: 'Debt', child: Text("Ghi nợ")),
                ],
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),

              const Divider(height: 30, thickness: 2),

              // --- DANH SÁCH SẢN PHẨM ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sản phẩm (${_draftItems.length}):",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_draftItems.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _draftItems.clear();
                        });
                      },
                      child: const Text(
                        "Xóa hết",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),

              if (_draftItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "Danh sách trống",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              ..._draftItems.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng 1: Tên SP + Nút Xóa (X)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // [NÚT XÓA NHANH]
                            InkWell(
                              onTap: () => _removeItem(item),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 8),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Hàng 2: Giá + Input Số lượng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Giá và ĐVT
                            Text(
                              "${currencyFormat.format(item.price)} / ${item.unitName}",
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            // Bộ điều khiển số lượng ( -  Input  + )
                            Container(
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    onPressed: () => _updateQuantity(item, -1),
                                  ),
                                  // [Ô NHẬP SỐ LƯỢNG]
                                  SizedBox(
                                    width: 40,
                                    child: TextField(
                                      controller:
                                          _qtyControllers[item.productId],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (val) =>
                                          _onTypeQuantity(item, val),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    onPressed: () => _updateQuantity(item, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _draftItems.isEmpty ? null : _confirmOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
          ),
          child: const Text("Xác nhận"),
        ),
      ],
    );
  }
}
