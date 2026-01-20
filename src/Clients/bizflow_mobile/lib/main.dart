import 'package:bizflow_mobile/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

// --- SERVICE & CORE IMPORTS ---
import 'core/service_locator.dart';
import 'core/api_service.dart';
import 'services/fcm_service.dart';

// --- REPOSITORY IMPORTS ---
// [MỚI] Import Repo

// --- PROVIDER IMPORTS ---
import 'providers/auth_provider.dart';
import 'cart_provider.dart';

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
  // Bước này sẽ tạo sẵn ApiService và ProductRepository (Singleton)
  ServiceLocator.setup();

  // 3. Khởi tạo Hive (Local Database)
  await Hive.initFlutter();
  await Hive.openBox('productCache');
  await Hive.openBox('authBox');

  // 4. Khởi tạo FCM (Notification)
  try {
    FCMService().initialize();
  } catch (e) {
    print("⚠️ Lỗi khởi tạo FCM: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        // A. Cung cấp ApiService (Lấy từ Singleton ServiceLocator)
        Provider<ApiService>(create: (_) => ServiceLocator.apiService),

        // B. [QUAN TRỌNG] Cung cấp ProductRepository cho UI
        // UI sẽ gọi: context.read<ProductRepository>().getProducts()
        Provider<ProductRepository>(create: (_) => ServiceLocator.productRepo),

        // C. AuthProvider (Cần ApiService để login)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(ServiceLocator.apiService),
        ),

        // D. CartProvider
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
      // Logic điều hướng chính dựa trên trạng thái đăng nhập
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // 🔥 Màn hình chờ: Đang load từ Hive hoặc đang gọi API
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

          // Kiểm tra quyền Owner/Admin
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
