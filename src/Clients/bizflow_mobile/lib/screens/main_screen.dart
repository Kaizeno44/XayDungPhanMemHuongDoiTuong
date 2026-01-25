import 'package:flutter/material.dart';
import 'package:bizflow_mobile/screens/owner_dashboard_screen.dart';
import 'package:bizflow_mobile/screens/product_list_screen.dart';
import 'package:bizflow_mobile/screens/warehouse_screen.dart';
import 'package:bizflow_mobile/screens/debt_list_screen.dart'; // Import màn hình Sổ nợ

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const OwnerDashboardScreen(),
    const ProductListScreen(),
    const DebtListScreen(), // Tab mới
    const WarehouseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
            icon: Icon(Icons.account_balance_wallet),
            label: 'Sổ Nợ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Kho hàng'),
        ],
      ),
    );
  }
}
