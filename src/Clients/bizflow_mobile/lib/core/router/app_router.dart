import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// --- IMPORTS: PROVIDERS ---
import 'package:bizflow_mobile/providers/auth_provider.dart';

// --- IMPORTS: SCREENS ---
import 'package:bizflow_mobile/screens/login_screen.dart';
import 'package:bizflow_mobile/screens/main_screen.dart'; // <--- QUAN TRỌNG: Màn hình chứa Navigation Bar
import 'package:bizflow_mobile/screens/product_list_screen.dart';
import 'package:bizflow_mobile/cart_screen.dart'; // Nếu bạn có file này
// import 'package:bizflow_mobile/screens/stock_import_history_screen.dart';

part 'app_router.g.dart';

// Key này giúp Router điều khiển Navigator gốc
final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // 1. Lắng nghe AuthProvider
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard', // Mặc định vào Dashboard (MainScreen)
    // 2. Kích hoạt lắng nghe (RefreshListenable)
    refreshListenable: authState,

    // 3. Logic Bảo vệ (Guard) - Kiểm tra đăng nhập
    redirect: (context, state) {
      final bool isLoggedIn = authState.isAuthenticated;
      final bool isLoggingIn = state.uri.toString() == '/login';

      // A. Chưa đăng nhập mà đòi vào trang trong -> Đá về Login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // B. Đã đăng nhập mà lại vào trang Login -> Đá về Dashboard
      if (isLoggedIn && isLoggingIn) {
        // Có thể check role ở đây nếu cần phân quyền chi tiết
        // Hiện tại cho tất cả vào MainScreen (nơi có Dashboard + Kho + Sản phẩm)
        return '/dashboard';
      }

      // C. Cho phép đi tiếp
      return null;
    },

    // 4. Định nghĩa Tuyến đường (Routes)
    routes: [
      // Màn hình Đăng nhập
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Màn hình Chính (Chứa Navigation Bar)
      // Đây là thay đổi quan trọng nhất để hiện thanh điều hướng dưới đáy
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const MainScreen(),
      ),

      // Các màn hình phụ (Không có Navigation Bar)
      // Ví dụ: Khi bấm vào nút giỏ hàng, nó sẽ mở đè lên màn hình chính
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),

      // Route cho sản phẩm (Nếu muốn truy cập riêng lẻ, thường ít dùng nếu đã có MainScreen)
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
      ),
    ],
  );
}
