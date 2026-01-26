import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import để dùng SystemNavigator.pop()
import 'package:bizflow_mobile/screens/owner_dashboard_screen.dart';
import 'package:bizflow_mobile/screens/product_list_screen.dart';
import 'package:bizflow_mobile/screens/warehouse_screen.dart';
import 'package:bizflow_mobile/screens/debt_list_screen.dart'; // [QUAN TRỌNG] Import màn hình Sổ nợ

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  // Danh sách các màn hình (Đã thêm Sổ nợ vào cuối)
  final List<Widget> _screens = [
    const OwnerDashboardScreen(), // Index 0
    const ProductListScreen(), // Index 1
    const WarehouseScreen(), // Index 2
    const DebtListScreen(), // Index 3: Sổ nợ
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackButton();
      },
      child: Scaffold(
        // IndexedStack giữ trạng thái các màn hình khi chuyển tab
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          // Thiết lập Type Fixed để hiển thị đều 4 icon
          type: BottomNavigationBarType.fixed,

          // Theme global trong main.dart đã lo phần màu sắc
          items: const [
            // Tab 1: Tổng quan
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Tổng quan',
            ),
            // Tab 2: Sản phẩm
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory),
              label: 'Sản phẩm',
            ),
            // Tab 3: Kho hàng
            BottomNavigationBarItem(
              icon: Icon(Icons.warehouse_outlined),
              activeIcon: Icon(Icons.warehouse),
              label: 'Kho hàng',
            ),
            // Tab 4: Sổ nợ (Đã thêm lại)
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined), // Icon sách/sổ
              activeIcon: Icon(Icons.menu_book),
              label: 'Sổ nợ',
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC XỬ LÝ NÚT BACK (ANDROID) ---
  void _handleBackButton() {
    // 1. Nếu đang ở tab khác (không phải Tổng quan), quay về tab Tổng quan
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // 2. Nếu đang ở tab Tổng quan, yêu cầu nhấn 2 lần để thoát
    final now = DateTime.now();
    if (_lastPressedAt == null ||
        now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
      _lastPressedAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhấn lần nữa để thoát ứng dụng'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        ),
      );
      return;
    }

    // 3. Thoát ứng dụng
    SystemNavigator.pop();
  }
}
