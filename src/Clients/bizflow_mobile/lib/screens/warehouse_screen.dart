import 'package:flutter/material.dart';
import 'stock_import_history_screen.dart';
import 'stock_import_create_screen.dart'; // <--- Import màn hình nhập hàng mới

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Kho hàng'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'LỊCH SỬ NHẬP', icon: Icon(Icons.history)),
            Tab(text: 'NHẬP HÀNG MỚI', icon: Icon(Icons.add_box)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Màn hình lịch sử (Giữ nguyên)
          const StockImportHistoryScreen(),

          // Tab 2: Màn hình nhập hàng mới (ĐÃ CẬP NHẬT)
          // Thay thế toàn bộ Column cũ bằng Widget chuyên dụng này
          const StockImportCreateScreen(),
        ],
      ),
    );
  }
}
