import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:signalr_core/signalr_core.dart'; // Import SignalR

import 'cart_provider.dart';
import 'product_list_screen.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'core/config/api_config.dart'; // Import ApiConfig

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Khởi tạo Hive
  await Hive.openBox('productCache'); // Mở một box để lưu sản phẩm

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
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: authProvider.isAuthenticated
          ? const ProductListScreen()
          : const LoginScreen(),
    );
  }
}
