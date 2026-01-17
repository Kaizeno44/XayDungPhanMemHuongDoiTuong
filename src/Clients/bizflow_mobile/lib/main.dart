import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:firebase_core/firebase_core.dart'; // [MỚI] Import Firebase Core
// Import SignalR (Giữ nguyên của bạn)

// [MỚI] Import Service FCM bạn vừa tạo ở bước trước
import 'services/fcm_service.dart';

// Các import cũ của bạn
import 'cart_provider.dart';
import 'product_list_screen.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase (Cái này nhanh, nên await được)
  try {
    await Firebase.initializeApp();
    print("✅ Firebase đã khởi tạo thành công");
  } catch (e) {
    print("❌ Lỗi khởi tạo Firebase: $e");
  }

  // 2. [SỬA ĐỔI QUAN TRỌNG]
  // Bỏ từ khóa 'await' ở đây đi.
  // Để cho nó chạy ngầm (async), không bắt người dùng phải đợi lấy token xong mới thấy App.
  FCMService().initialize();

  // 3. Khởi tạo Hive
  await Hive.initFlutter();
  await Hive.openBox('productCache');

  // 4. Chạy App ngay lập tức
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
    // Lắng nghe trạng thái đăng nhập từ AuthProvider
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BizFlow Mobile', // Thêm title cho rõ ràng
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      // Logic điều hướng: Nếu đã đăng nhập -> Vào danh sách SP, chưa -> Vào Login
      home: authProvider.isAuthenticated
          ? const ProductListScreen()
          : const LoginScreen(),
    );
  }
}
