import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'cart_provider.dart';
import 'models.dart';
import 'order_history_screen.dart'; // <--- QUAN TRỌNG: Đã thêm dòng này

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Thay đổi StoreID này bằng ID thực tế trong database của bạn
  final String storeId = "3fa85f64-5717-4562-b3fc-2c963f66afa6";

  final List<Customer> customers = [
    Customer(id: "c4608c0c-847e-468e-976e-5776d5483011", name: "Nguyễn Văn A"),
    Customer(id: "d5708c0c-847e-468e-976e-5776d5483022", name: "Trần Thị B"),
  ];

  String? selectedCustomerId;
  String selectedPaymentMethod = "Cash";
  bool isLoading = false;

  Future<void> createOrder(CartProvider cart) async {
    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn khách hàng")));
      return;
    }
    setState(() => isLoading = true);

    // Đã thay đổi cổng từ 5003 sang 5103 để khớp với cấu hình ApiGateway
    const String apiUrl = "http://10.0.2.2:5103/api/Orders";

    final requestBody = {
      "customerId": selectedCustomerId,
      "storeId": storeId,
      "paymentMethod": selectedPaymentMethod,
      "items": cart.items.map((e) => e.toJson()).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        cart.clearCart();
        if (mounted) _showSuccessDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Lỗi: ${response.body}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Thành công"),
        content: const Text("Đơn hàng đã được tạo!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: selectedCustomerId,
              hint: const Text("Chọn khách hàng"),
              items: customers
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedCustomerId = val),
            ),

            // === ĐÃ THÊM NÚT XEM LỊCH SỬ TẠI ĐÂY ===
            if (selectedCustomerId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.history, color: Colors.blue),
                  label: const Text("Xem lịch sử mua hàng"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderHistoryScreen(customerId: selectedCustomerId!),
                      ),
                    );
                  },
                ),
              ),
            // =======================================

            RadioListTile(
              title: const Text("Tiền mặt"),
              value: "Cash",
              groupValue: selectedPaymentMethod,
              onChanged: (val) =>
                  setState(() => selectedPaymentMethod = val.toString()),
            ),
            RadioListTile(
              title: const Text("Ghi nợ"),
              value: "Debt",
              groupValue: selectedPaymentMethod,
              onChanged: (val) =>
                  setState(() => selectedPaymentMethod = val.toString()),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isLoading || cart.items.isEmpty)
                    ? null
                    : () => createOrder(cart),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("TẠO ĐƠN HÀNG"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
