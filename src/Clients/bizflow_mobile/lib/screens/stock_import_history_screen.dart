import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/warehouse_service.dart';
import '../models/stock_import.dart';

class StockImportHistoryScreen extends ConsumerStatefulWidget {
  const StockImportHistoryScreen({super.key});

  @override
  ConsumerState<StockImportHistoryScreen> createState() =>
      _StockImportHistoryScreenState();
}

class _StockImportHistoryScreenState
    extends ConsumerState<StockImportHistoryScreen> {
  bool _isLoading = true;
  List<StockImport> _imports = [];
  final _warehouseService = WarehouseService();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final authState = ref.read(authNotifierProvider);
    final storeId = authState.currentUser?.storeId;

    if (storeId != null) {
      final data = await _warehouseService.getImportHistory(storeId);
      if (mounted) {
        setState(() {
          _imports = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Chưa có phiếu nhập hàng nào",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchHistory();
              },
              child: const Text("Tải lại"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _imports.length,
        itemBuilder: (context, index) {
          final item = _imports[index];
          return _buildImportCard(item);
        },
      ),
    );
  }

  Widget _buildImportCard(StockImport item) {
    // Vì Backend hiện tại lưu từng dòng chi tiết (Flat List) nên không có "Status" tổng.
    // Mặc định những phiếu đã lưu vào DB là "Hoàn thành".

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng 1: Tên sản phẩm + Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productName, // [SỬA] Thay item.code bằng tên sản phẩm
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.formattedTotal, // [SỬA] Thay formattedTotalCost
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dòng 2: Số lượng & Đơn vị
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${item.formattedQuantity} ${item.unitName}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "x ${item.formattedUnitCost}", // Hiển thị giá đơn vị
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),

            const Divider(height: 20),

            // Dòng 3: Nhà cung cấp + Ngày tháng
            Row(
              children: [
                const Icon(Icons.store, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.supplierName, // [SỬA] Dùng supplierName thay createdBy
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item.formattedDate,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
