import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider (Legacy)
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod; // Riverpod (New)
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- SERVICE & CORE IMPORTS ---
import 'package:bizflow_mobile/core/router/app_router.dart';
import 'package:bizflow_mobile/repositories/product_repository.dart';
import 'package:bizflow_mobile/services/signalr_service.dart';
import 'package:bizflow_mobile/core/service_locator.dart';
import 'package:bizflow_mobile/core/api_service.dart';
import 'package:bizflow_mobile/services/fcm_service.dart';

// --- PROVIDER IMPORTS ---
import 'package:bizflow_mobile/providers/auth_provider.dart';

// 1. Định nghĩa Constants cho Hive
class StorageConstants {
  static const String productBox = 'productCache';
  static const String authBox = 'authBox';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase đã khởi tạo thành công");
  } catch (e) {
    debugPrint("❌ Lỗi khởi tạo Firebase: $e");
  }

  // 3. Khởi tạo ServiceLocator
  ServiceLocator.setup();

  // 4. Khởi tạo Hive
  await Hive.initFlutter();
  await Hive.openBox(StorageConstants.productBox);
  await Hive.openBox(StorageConstants.authBox);

  // 5. Khởi tạo Locale
  await initializeDateFormatting('vi', null);

  // 6. Khởi tạo FCM
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

/// AppConfig: Cầu nối giữa Riverpod và Provider cũ
class AppConfig extends riverpod.ConsumerWidget {
  const AppConfig({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ServiceLocator.apiService),
        Provider<ProductRepository>(create: (_) => ServiceLocator.productRepo),
        
        // --- LEGACY AUTH PROVIDER ---
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
    // 1. Router từ Riverpod
    final goRouter = ref.watch(appRouterProvider);

    // 2. LOGIC SIGNALR (Tự động kết nối/ngắt kết nối)
    // Lắng nghe trạng thái Auth để kết nối SignalR
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

    // 3. DESIGN SYSTEM
    const primaryColor = Colors.orange;
    final primaryDark = Colors.orange[800]!;
    final errorColor = Colors.red[700]!;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryDark,
      error: errorColor,
      secondary: Colors.blue,
      surface: Colors.white,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BizFlow Mobile',
      routerConfig: goRouter,
      
      // --- THEME SETUP ---
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Roboto',

        // AppBar Theme
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

        // ElevatedButton Theme
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

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: errorColor, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIconColor: primaryDark,
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
        ),

        // Floating Action Button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}