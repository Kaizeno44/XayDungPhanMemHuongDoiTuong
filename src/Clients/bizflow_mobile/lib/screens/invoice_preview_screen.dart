import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models.dart';
import '../utils/invoice_generator.dart';

class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.items,
    required this.customerName,
    required this.paymentMethod,
    required this.totalAmount,
    required this.storeId,
  });

  final List<CartItem> items;
  final String customerName;
  final String paymentMethod;
  final double totalAmount;
  final String storeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xem trước Hóa đơn"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // Widget này tự động tạo giao diện Xem trước + Nút Share + Nút In
      body: PdfPreview(
        build: (format) => InvoiceGenerator.generate(
          format: format,
          items: items,
          customerName: customerName,
          paymentMethod: paymentMethod,
          totalAmount: totalAmount,
          storeId: storeId,
        ),
        // Tắt bớt mấy tính năng không cần thiết nếu muốn gọn
        allowSharing: true, // Đảm bảo nút Share được bật
        allowPrinting: true,
        canChangeOrientation: false, // Khóa xoay ngang dọc nếu muốn
        canChangePageFormat: false, // Khóa đổi khổ giấy nếu muốn cố định A4
      ),
    );
  }
}
