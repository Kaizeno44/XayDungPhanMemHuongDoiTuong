import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Import các file cần thiết
import '../providers/auth_provider.dart';
import '../services/warehouse_service.dart';
import '../features/warehouse/import_controller.dart';
import '../features/products/product_list_controller.dart';
import '../models.dart'; // Đảm bảo import model ImportItem, Product...

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

    return GestureDetector(
      // [UX] Chạm ra ngoài để ẩn bàn phím
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Tạo phiếu nhập',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.orange[800], // [THEME] Đồng bộ màu cam
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (importList.isNotEmpty)
              IconButton(
                onPressed: () {
                  _showClearConfirmation(context);
                },
                tooltip: "Xóa tất cả",
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
              ),
          ],
        ),
        body: Column(
          children: [
            // 1. Danh sách sản phẩm
            Expanded(
              child: importList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: importList.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // Nút thêm sản phẩm ở cuối danh sách
                        if (index == importList.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 40,
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () => _showProductPicker(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: Colors.orange[800]!),
                                foregroundColor: Colors.orange[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text("Thêm sản phẩm khác"),
                            ),
                          );
                        }
                        // Item nhập liệu
                        return _buildInputCard(importList[index]);
                      },
                    ),
            ),

            // 2. Thanh tổng kết & Nút gửi (Bottom Bar)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tổng tạm tính:",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalEstimated),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || importList.isEmpty)
                            ? null
                            : () => _showConfirmDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
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
                                  letterSpacing: 1,
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
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_shopping_cart_rounded,
              size: 64,
              color: Colors.orange[200],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Chưa có sản phẩm nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vui lòng thêm sản phẩm để nhập kho",
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showProductPicker(context),
            icon: const Icon(Icons.add),
            label: const Text("Chọn sản phẩm"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(ImportItem item) {
    // [QUAN TRỌNG] Sử dụng Key để Flutter tracking đúng item khi xóa/thêm
    return Card(
      key: ValueKey(item.product.id),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header: Tên SP + Nút xóa
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.orange[800],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${item.product.sku} | Đơn vị: ${item.product.unitName}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    ref
                        .read(importControllerProvider.notifier)
                        .removeProduct(item.product.id);
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            // Form nhập liệu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Số lượng
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    initialValue: item.quantity > 0
                        ? item.quantity.toString().replaceAll('.0', '')
                        : '', // Để trống nếu là 0 để dễ nhập
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: "Số lượng",
                      hintText: "0",
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (val) {
                      // Thay dấu phẩy thành chấm nếu user nhập kiểu Việt Nam
                      double qty =
                          double.tryParse(val.replaceAll(',', '.')) ?? 0;
                      ref
                          .read(importControllerProvider.notifier)
                          .updateQuantity(item.product.id, qty);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Giá nhập
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    initialValue: item.unitCost > 0
                        ? item.unitCost.toInt().toString()
                        : '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Giá nhập",
                      hintText: "0",
                      suffixText: '₫',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (val) {
                      double cost =
                          double.tryParse(val.replaceAll(',', '.')) ?? 0;
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

  // --- MODALS & DIALOGS ---

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa danh sách?"),
        content: const Text("Bạn có muốn xóa toàn bộ sản phẩm đã chọn không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Không"),
          ),
          TextButton(
            onPressed: () {
              ref.read(importControllerProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Chọn sản phẩm",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      CloseButton(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                // Product List
                Expanded(
                  child: asyncProducts.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text(
                        "Lỗi tải dữ liệu",
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(
                          child: Text("Không tìm thấy sản phẩm nào"),
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
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.orange[300],
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "Tồn: ${product.inventory?.quantity ?? 0} ${product.unitName}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(importControllerProvider.notifier)
                                    .addProduct(product);
                                Navigator.pop(context);
                              },
                              child: const Text("Thêm"),
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

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange[800]),
            const SizedBox(width: 8),
            const Text("Xác nhận nhập kho"),
          ],
        ),
        content: const Text(
          "Bạn có chắc chắn muốn nhập các sản phẩm này vào kho không? Hành động này sẽ cập nhật số lượng tồn kho.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Xem lại", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitImport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
            ),
            child: const Text("Đồng ý nhập"),
          ),
        ],
      ),
    );
  }

  // --- LOGIC API ---

  Future<void> _submitImport() async {
    final list = ref.read(importControllerProvider);

    // Validate nhanh
    if (list.any((item) => item.quantity <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Vui lòng kiểm tra lại số lượng nhập > 0"),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentUser = ref.read(authNotifierProvider).currentUser;
    if (currentUser?.storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi: Không tìm thấy thông tin cửa hàng")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Map dữ liệu
    final details = list.map((item) {
      int unitId = 0;
      try {
        if (item.product.productUnits.isNotEmpty) {
          final baseUnit = item.product.productUnits.firstWhere(
            (u) => u.isBaseUnit,
            orElse: () => item.product.productUnits.first,
          );
          unitId = baseUnit.id;
        }
      } catch (_) {}

      return {
        "productId": item.product.id,
        "quantity": item.quantity,
        "unitCost": item.unitCost,
        "productUnitId": unitId,
        "unitId": unitId,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("❌ Lỗi khi tạo phiếu nhập. Thử lại sau."),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
