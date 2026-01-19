import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

// --- SERVICE & CORE IMPORTS ---
import 'core/service_locator.dart'; // 👈 [QUAN TRỌNG] Thêm dòng này để fix lỗi
import 'services/fcm_service.dart';

// --- PROVIDER IMPORTS ---
import 'providers/auth_provider.dart';
import 'cart_provider.dart'; // Đảm bảo import đúng đường dẫn file CartProvider của bạn

// --- SCREEN IMPORTS ---
import 'screens/login_screen.dart';
import 'product_list_screen.dart';
import 'screens/owner_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  try {
    await Firebase.initializeApp();
    print("✅ Firebase đã khởi tạo thành công");
  } catch (e) {
    print("❌ Lỗi khởi tạo Firebase: $e");
  }

  // 2. Khởi tạo ServiceLocator (Dependency Injection)
  // 👇 DÒNG NÀY SẼ SỬA LỖI "LateInitializationError: Field productRepo..."
  ServiceLocator.setup();

  // 3. Khởi tạo FCM
  try {
    FCMService().initialize();
  } catch (e) {
    print("⚠️ Lỗi khởi tạo FCM: $e");
  }

  // 4. Khởi tạo Hive
  await Hive.initFlutter();
  await Hive.openBox('productCache');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BizFlow Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      // Logic điều hướng chính
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // 🔥 Màn hình chờ: Nếu chưa kiểm tra Hive xong -> Hiện loading
          if (!auth.isAuthCheckComplete) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // --- 1. CHƯA ĐĂNG NHẬP ---
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }

          // --- 2. ĐÃ ĐĂNG NHẬP -> PHÂN QUYỀN ---
          final rawRole = auth.role;
          print("🔍 DEBUG ROLE: '$rawRole'");

          // Chuẩn hóa role
          final role = rawRole?.trim().toLowerCase() ?? '';

          // Kiểm tra quyền Owner
          if (role == 'owner' || role == 'admin' || role == 'quản lý') {
            print("✅ ĐIỀU HƯỚNG: -> Dashboard (Owner)");
            return const OwnerDashboardScreen();
          }

          // Mặc định: Nhân viên
          print("ℹ️ ĐIỀU HƯỚNG: -> Bán hàng (Staff)");
          return const ProductListScreen();
        },
      ),
    );
  }
}
