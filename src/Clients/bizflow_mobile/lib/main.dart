import 'package:flutter/material.dart';
import 'product_list_screen.dart'; // Nhập file màn hình vừa tạo

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ Debug ở góc
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const ProductListScreen(), // Gọi màn hình danh sách ra
    );
  }
}