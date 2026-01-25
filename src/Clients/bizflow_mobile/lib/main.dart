import 'package:bizflow_mobile/core/router/app_router.dart';
import 'package:bizflow_mobile/repositories/product_repository.dart';
import 'package:bizflow_mobile/services/signalr_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider cũ
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod; // Riverpod
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

// --- SERVICE & CORE IMPORTS ---
import 'core/service_locator.dart';
import 'core/api_service.dart';
import 'services/fcm_service.dart';

// --- PROVIDER IMPORTS ---
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase đã khởi tạo thành công");
  } catch (e) {
    debugPrint("❌ Lỗi khởi tạo Firebase: $e");
  }

  // 2. Khởi tạo ServiceLocator (BẮT BUỘC cho code cũ)
  ServiceLocator.setup();

  // 3. Khởi tạo Hive (BẮT BUỘC cho lưu trữ local)
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

// AppConfig: Cung cấp các Provider cũ (Legacy)
class AppConfig extends StatelessWidget {
  const AppConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ServiceLocator.apiService),
        Provider<ProductRepository>(create: (_) => ServiceLocator.productRepo),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(ServiceLocator.apiService),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends riverpod.ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);

    // --- LOGIC SIGNALR (Tự động kết nối khi Login) ---
    ref.listen<bool>(
      authNotifierProvider.select((value) => value.isAuthenticated),
      (previous, isAuthenticated) {
        if (isAuthenticated && (previous == false || previous == null)) {
          debugPrint("🚀 Auth Changed: Login -> Connecting SignalR...");
          ref.read(signalRServiceProvider.notifier).connect();
        } else if (!isAuthenticated && (previous == true)) {
          debugPrint("🚀 Auth Changed: Logout -> Disconnecting SignalR...");
          ref.read(signalRServiceProvider.notifier).disconnect();
        }
      },
    );

    // --- DESIGN SYSTEM (COLORS) ---
    const primaryColor = Colors.orange;
    final primaryDark = Colors.orange[800]!;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryDark,
      secondary: Colors.blue,
      surface: Colors.white,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BizFlow Mobile',

      // --- THEME SETUP (Code mới của bạn) ---
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,

        // 1. AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        // 2. ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // 3. Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryDark, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIconColor: primaryDark,
        ),

        // 4. Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryDark,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // 5. Card Theme (Đã fix lỗi CardThemeData)
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
        ),

        // 6. Floating Action Button Theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
        ),
      ),

      routerConfig: goRouter,
    );
  }
}
