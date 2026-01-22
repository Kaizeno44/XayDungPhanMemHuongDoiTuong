import 'package:bizflow_mobile/core/router/app_router.dart';
import 'package:bizflow_mobile/repositories/product_repository.dart';
// Lưu ý: Kiểm tra đúng đường dẫn file này trong máy bạn (lib/services/ hay lib/core/services/)
import 'package:bizflow_mobile/services/signalr_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider cũ
// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart'
    as riverpod; // Riverpod (dùng alias để tránh trùng tên)
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

// --- SERVICE & CORE IMPORTS ---
import 'core/service_locator.dart';
import 'core/api_service.dart';
import 'services/fcm_service.dart';

// --- PROVIDER IMPORTS ---
import 'providers/auth_provider.dart';
// ❌ ĐÃ XÓA: import 'cart_provider.dart'; (Vì đã chuyển sang CartController Riverpod)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase đã khởi tạo thành công");
  } catch (e) {
    debugPrint("❌ Lỗi khởi tạo Firebase: $e");
  }

  // 2. Khởi tạo ServiceLocator (Cho các Service cũ)
  ServiceLocator.setup();

  // 3. Khởi tạo Hive
  await Hive.initFlutter();
  await Hive.openBox('productCache');
  await Hive.openBox('authBox');

  // 4. Khởi tạo FCM
  try {
    FCMService().initialize();
  } catch (e) {
    debugPrint("⚠️ Lỗi khởi tạo FCM: $e");
  }

  runApp(
    // Bọc App trong ProviderScope của Riverpod
    const riverpod.ProviderScope(child: AppConfig()),
  );
}

// AppConfig: Cung cấp các Provider cũ (Legacy) cho các màn hình chưa chuyển đổi
class AppConfig extends StatelessWidget {
  const AppConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // A. ApiService
        Provider<ApiService>(create: (_) => ServiceLocator.apiService),

        // B. ProductRepository
        Provider<ProductRepository>(create: (_) => ServiceLocator.productRepo),

        // C. AuthProvider (Vẫn giữ lại vì dùng chung nhiều nơi)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(ServiceLocator.apiService),
        ),

        // ❌ ĐÃ XÓA: CartProvider
        // Chúng ta không cung cấp CartProvider cũ nữa để ép buộc UI dùng CartController mới
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends riverpod.ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    // 1. Lấy cấu hình Router
    final goRouter = ref.watch(appRouterProvider);

    // 2. [QUAN TRỌNG] Logic quản lý SignalR tự động theo Auth
    // Sử dụng .select để chỉ lắng nghe giá trị boolean isAuthenticated
    ref.listen<bool>(
      authNotifierProvider.select((value) => value.isAuthenticated),
      (previous, isAuthenticated) {
        // A. Vừa Đăng nhập thành công (false -> true)
        // Hoặc mở app đã có sẵn token (previous là null/false)
        if (isAuthenticated && (previous == false || previous == null)) {
          debugPrint(
            "🚀 Auth Changed: Login Detected -> Connecting SignalR...",
          );
          ref.read(signalRServiceProvider.notifier).connect();
        }
        // B. Vừa Đăng xuất (true -> false)
        else if (!isAuthenticated && (previous == true)) {
          debugPrint(
            "🚀 Auth Changed: Logout Detected -> Disconnecting SignalR...",
          );
          ref.read(signalRServiceProvider.notifier).disconnect();
        }
      },
    );

    return MaterialApp.router(
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
      routerConfig: goRouter,
    );
  }
}
