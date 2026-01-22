import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Import AuthProvider (cầu nối vừa tạo)
import 'package:bizflow_mobile/providers/auth_provider.dart';

// Import các màn hình
import 'package:bizflow_mobile/screens/login_screen.dart';
import 'package:bizflow_mobile/screens/owner_dashboard_screen.dart';
import 'package:bizflow_mobile/product_list_screen.dart'; // Màn hình Riverpod mới
// import 'package:bizflow_mobile/screens/stock_import_history_screen.dart';
// import 'package:bizflow_mobile/cart_screen.dart';

part 'app_router.g.dart';

// Key này giúp Router điều khiển Navigator gốc
final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // 1. Lắng nghe AuthProvider
  // Bất cứ khi nào notifyListeners() được gọi bên AuthProvider, Router sẽ chạy lại logic redirect
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard', // Mặc định thử vào Dashboard
    // 2. Kích hoạt lắng nghe (RefreshListenable)
    // Đây là chìa khóa để GoRouter tự động chuyển trang khi Login/Logout
    refreshListenable: authState,

    // 3. Logic Bảo vệ (Guard)
    redirect: (context, state) {
      // Kiểm tra trạng thái đăng nhập
      final bool isLoggedIn = authState.isAuthenticated;
      final bool isLoggingIn = state.uri.toString() == '/login';

      // A. Chưa đăng nhập mà đòi vào trang trong -> Đá về Login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // B. Đã đăng nhập mà lại vào trang Login -> Đá về Dashboard
      if (isLoggedIn && isLoggingIn) {
        // Có thể check role ở đây để điều hướng (Owner -> Dashboard, Staff -> Products)
        final role = (authState.currentUser?.role ?? '').toLowerCase();
        if (role == 'owner' || role == 'admin') {
          return '/dashboard';
        } else {
          return '/products'; // Nhân viên vào thẳng kho
        }
      }

      // C. Cho phép đi tiếp
      return null;
    },

    // 4. Định nghĩa Tuyến đường (Routes)
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
        routes: [
          // Ví dụ Route con: /products/detail
          // GoRoute(path: 'detail', builder: ...),
        ],
      ),
      // Thêm các route khác (Cart, History...) tại đây
    ],
  );
}
