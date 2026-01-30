import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart'; // Cần import để format tên file
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
    // Lấy màu chủ đạo từ Theme (đã cấu hình ở main.dart là màu Cam)
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Tạo tên file duy nhất dựa trên thời gian thực
    final String fileName = 'HoaDon_${DateTime.now().millisecondsSinceEpoch}.pdf';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Xem trước Hóa đơn",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // SỬ DỤNG MÀU TỪ THEME (Thay vì Colors.blue)
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PdfPreview(
        // 1. Hàm tạo PDF
        build: (format) => InvoiceGenerator.generate(
          format: format,
          items: items,
          customerName: customerName,
          paymentMethod: paymentMethod,
          totalAmount: totalAmount,
          storeId: storeId,
        ),
        
        // 2. Tên file khi Share/Save (Rất quan trọng cho trải nghiệm người dùng)
        pdfFileName: fileName,

        // 3. Tùy chỉnh giao diện Preview
        allowSharing: true, // Cho phép chia sẻ (Zalo, Mail...)
        allowPrinting: true, // Cho phép in

        // Khóa xoay và format để giao diện ổn định (như yêu cầu cũ)
        canChangeOrientation: false, 
        canChangePageFormat: false, 

        // 4. Giao diện tùy chỉnh (Màu icon, Loading, Error)
        previewPageMargin: const EdgeInsets.all(10), // Khoảng cách viền
        
        // Tùy chỉnh loading (Xoay vòng tròn màu Cam)
        loadingWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 10),
              const Text("Đang tạo hóa đơn..."),
            ],
          ),
        ),

        // Tùy chỉnh khi lỗi
        onError: (context, error) => Center(
          child: Text(
            "Lỗi khi tạo PDF: $error",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
