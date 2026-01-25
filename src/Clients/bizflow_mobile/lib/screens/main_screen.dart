import 'package:flutter/material.dart';
// Import các màn hình
import 'package:bizflow_mobile/screens/owner_dashboard_screen.dart';
import 'package:bizflow_mobile/screens/product_list_screen.dart';
import 'package:bizflow_mobile/screens/warehouse_screen.dart';
import 'package:bizflow_mobile/screens/debt_list_screen.dart'; // <--- 1. NHỚ IMPORT FILE NÀY

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Danh sách màn hình (Phải khớp thứ tự với BottomNavigationBar)
  final List<Widget> _screens = [
    const OwnerDashboardScreen(), // Tab 0
    const ProductListScreen(), // Tab 1
    const DebtListScreen(), // Tab 2: <--- 2. THÊM SỔ NỢ VÀO ĐÂY
    const WarehouseScreen(), // Tab 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giúp giữ trạng thái màn hình khi chuyển tab
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType
            .fixed, // Bắt buộc dùng fixed khi có >= 4 tab

        items: const [
          // Tab 0
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          // Tab 1
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Sản phẩm',
          ),
          // Tab 2: Sổ Nợ (Mới) <--- 3. THÊM ICON VÀO ĐÂY
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Sổ Nợ',
          ),
          // Tab 3
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Kho hàng',
          ),
        ],
      ),
    );
  }
}
