import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../services/warehouse_service.dart';
import '../features/warehouse/import_controller.dart';
import '../features/products/product_list_controller.dart';

class StockImportCreateScreen extends ConsumerStatefulWidget {
  const StockImportCreateScreen({super.key});

  @override
  ConsumerState<StockImportCreateScreen> createState() =>
      _StockImportCreateScreenState();
}

class _StockImportCreateScreenState
    extends ConsumerState<StockImportCreateScreen> {
  final _warehouseService = WarehouseService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final importList = ref.watch(importControllerProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Tính tổng tiền dự kiến
    double totalEstimated = importList.fold(0, (sum, item) => sum + item.total);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: importList.isNotEmpty
          ? AppBar(
              title: const Text(
                'Danh sách chọn',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                TextButton.icon(
                  onPressed: () {
                    ref.read(importControllerProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text(
                    "Xóa hết",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // 1. Danh sách sản phẩm đã chọn
          Expanded(
            child: importList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_shopping_cart,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Chưa có sản phẩm nào",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showProductPicker(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Chọn sản phẩm"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: importList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == importList.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => _showProductPicker(context),
                            icon: const Icon(Icons.add),
                            label: const Text("Thêm sản phẩm khác"),
                          ),
                        );
                      }
                      return _buildInputCard(importList[index]);
                    },
                  ),
          ),

          // 2. Thanh tổng kết & Nút gửi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tổng tiền nhập:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currencyFormat.format(totalEstimated),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || importList.isEmpty)
                          ? null
                          : () => _showConfirmDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "HOÀN TẤT NHẬP KHO",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng dòng nhập liệu
  Widget _buildInputCard(ImportItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Tên sản phẩm & Nút xóa
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.orange[800],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    ref
                        .read(importControllerProvider.notifier)
                        .removeProduct(item.product.id);
                  },
                ),
              ],
            ),
            const Divider(),
            // Nhập Số lượng & Đơn giá
            Row(
              children: [
                // Số lượng
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Số lượng",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      double qty = double.tryParse(val) ?? 0;
                      ref
                          .read(importControllerProvider.notifier)
                          .updateQuantity(item.product.id, qty);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Giá nhập
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.unitCost.toInt().toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Giá nhập",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      suffixText: '₫',
                    ),
                    onChanged: (val) {
                      double cost = double.tryParse(val) ?? 0;
                      ref
                          .read(importControllerProvider.notifier)
                          .updateCost(item.product.id, cost);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal chọn sản phẩm
  void _showProductPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          final asyncProducts = ref.watch(productListControllerProvider);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search),
                      const SizedBox(width: 8),
                      const Text(
                        "Chọn sản phẩm",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Product List
                Expanded(
                  child: asyncProducts.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text("Lỗi: $err")),
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(
                          child: Text("Không có sản phẩm nào"),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final product = products[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "SKU: ${product.sku} | Tồn: ${product.inventory?.quantity ?? 0}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[50],
                                foregroundColor: Colors.orange[800],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(importControllerProvider.notifier)
                                    .addProduct(product);
                                Navigator.pop(context);
                              },
                              child: const Text("Chọn"),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Dialog xác nhận
  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận nhập kho"),
        content: const Text(
          "Bạn có chắc chắn muốn nhập các sản phẩm này vào kho không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitImport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
            ),
            child: const Text("Đồng ý", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC GỬI API (ĐÃ SỬA LỖI 404) ---
  Future<void> _submitImport() async {
    final list = ref.read(importControllerProvider);

    // Validate
    if (list.any((item) => item.quantity <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Số lượng nhập phải lớn hơn 0"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Lấy Store ID
    final currentUser = ref.read(authNotifierProvider).currentUser;
    if (currentUser?.storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi: Không tìm thấy thông tin cửa hàng"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Map dữ liệu
    final details = list.map((item) {
      int unitId = 0;

      // Tìm ID của Base Unit
      try {
        if (item.product.productUnits.isNotEmpty) {
          final baseUnit = item.product.productUnits.firstWhere(
            (u) => u.isBaseUnit,
            orElse: () => item.product.productUnits.first,
          );
          unitId = baseUnit.id;
        }
      } catch (e) {
        print("⚠️ Không lấy được Unit ID: $e");
      }

      return {
        "productId": item.product.id,
        "quantity": item.quantity,
        "unitCost": item.unitCost,

        // --- QUAN TRỌNG: Gửi cả 2 tên Key để "bao vây" lỗi 404 ---
        "productUnitId": unitId, // Tên thường dùng 1
        "unitId": unitId, // Tên thường dùng 2
        // ----------------------------------------------------------
      };
    }).toList();

    // Gọi API
    final success = await _warehouseService.createImport(
      storeId: currentUser!.storeId!,
      details: details,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ref.read(importControllerProvider.notifier).clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Nhập kho thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Lỗi khi tạo phiếu nhập. Vui lòng thử lại."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
