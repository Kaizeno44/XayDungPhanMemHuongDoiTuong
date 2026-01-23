import 'package:bizflow_mobile/screens/product_list_screen.dart';
import 'package:flutter/material.dart';
import 'owner_dashboard_screen.dart';
import 'warehouse_screen.dart'; // Chúng ta sẽ tạo file này ở bước 2

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Danh sách các màn hình tương ứng với 3 tab
  final List<Widget> _screens = [
    const OwnerDashboardScreen(), // Tab 0
    const ProductListScreen(), // Tab 1
    const WarehouseScreen(), // Tab 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiển thị màn hình theo index hiện tại
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: 'Kho hàng',
          ),
        ],
      ),
    );
  }
}
