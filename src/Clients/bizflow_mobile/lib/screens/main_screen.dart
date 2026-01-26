import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // [MỚI] Import Riverpod

import '../providers/auth_provider.dart'; // Import AuthProvider để lấy Role
import 'owner_dashboard_screen.dart';
import 'product_list_screen.dart';
import 'warehouse_screen.dart';
import 'debt_list_screen.dart';

// [MỚI] Chuyển thành ConsumerStatefulWidget để lắng nghe Provider
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  // Khai báo danh sách rỗng, sẽ khởi tạo trong build
  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin User hiện tại từ AuthProvider
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.currentUser?.role;

    // 2. Xây dựng danh sách màn hình dựa trên Role
    // Lưu ý: Bạn cần kiểm tra chính xác chuỗi role trong DB của bạn là "Owner", "Admin" hay "Merchant"
    final isOwner = userRole == 'Owner' || userRole == 'Admin';

    _screens = [];
    _navItems = [];

    // --- A. QUYỀN CHỦ CỬA HÀNG (Thấy Dashboard) ---
    if (isOwner) {
      _screens.add(const OwnerDashboardScreen());
      _navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Tổng quan',
        ),
      );
    }

    // --- B. CÁC MÀN HÌNH CHUNG (Ai cũng thấy) ---

    // 1. Sản phẩm (Bán hàng/POS)
    _screens.add(const ProductListScreen());
    _navItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory),
        label: 'Sản phẩm',
      ),
    );

    // 2. Kho hàng (Nhập kho)
    _screens.add(const WarehouseScreen());
    _navItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.warehouse_outlined),
        activeIcon: Icon(Icons.warehouse),
        label: 'Kho hàng',
      ),
    );

    // 3. Sổ nợ
    _screens.add(const DebtListScreen());
    _navItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        activeIcon: Icon(Icons.menu_book),
        label: 'Sổ nợ',
      ),
    );

    // --- LOGIC AN TOÀN ---
    // Nếu index hiện tại vượt quá độ dài danh sách (do đổi role), reset về 0
    if (_currentIndex >= _screens.length) {
      _currentIndex = 0;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackButton();
      },
      child: Scaffold(
        // IndexedStack giữ trạng thái các màn hình
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          // Màu sắc đã được định nghĩa trong Theme (main.dart)
          items: _navItems,
        ),
      ),
    );
  }

  void _handleBackButton() {
    // Nếu đang ở tab khác tab đầu tiên, quay về tab đầu
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // Nếu đang ở tab đầu tiên (Dashboard hoặc Sản phẩm tùy role), confirm thoát
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

    SystemNavigator.pop();
  }
}
