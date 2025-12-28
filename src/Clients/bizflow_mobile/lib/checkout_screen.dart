import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'cart_provider.dart';
import 'models.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.customerId, // Giữ lại để tương thích, dù ta sẽ fetch lại list
    required this.storeId,
  });

  final String customerId;
  final String storeId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Store ID lấy từ dữ liệu thực tế của bạn
  final String storeId = "3fa85f64-5717-4562-b3fc-2c963f66afa6";

  // Biến lưu danh sách khách hàng từ API
  List<Customer> customers = [];

  // Các biến trạng thái
  String? selectedCustomerId;
  String selectedPaymentMethod = "Cash";
  bool isLoadingOrder = false; // Loading khi tạo đơn
  bool isLoadingCustomers = true; // Loading khi tải danh sách khách

  @override
  void initState() {
    super.initState();
    // Gọi API lấy khách hàng ngay khi màn hình mở lên
    _fetchCustomers();
  }

  // --- 1. HÀM LẤY DANH SÁCH KHÁCH HÀNG TỪ API ---
  Future<void> _fetchCustomers() async {
    final url = Uri.parse("http://10.0.2.2:5103/api/Customers");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          // Map dữ liệu JSON sang Model Customer
          customers = data
              .map(
                (json) => Customer(
                  id: json['id'],
                  // Lưu ý: Backend trả về 'fullName', Model của bạn là 'name'
                  name:
                      json['fullName'] ?? json['name'] ?? "Khách hàng ẩn danh",
                ),
              )
              .toList();

          isLoadingCustomers = false;
        });
      } else {
        _showSnackBar("Lỗi tải khách hàng: ${response.statusCode}");
        setState(() => isLoadingCustomers = false);
      }
    } catch (e) {
      _showSnackBar("Không thể kết nối Server để lấy khách hàng.");
      setState(() => isLoadingCustomers = false);
    }
  }

  // --- 2. HÀM TẠO ĐƠN HÀNG ---
  Future<void> createOrder(CartProvider cart) async {
    if (selectedCustomerId == null) {
      _showSnackBar("Vui lòng chọn khách hàng");
      return;
    }

    setState(() => isLoadingOrder = true);

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        cart.clearCart();
        if (mounted) _showSuccessDialog();
      } else {
        // Parse lỗi đẹp hơn
        String errorMsg = response.body;
        try {
          final errJson = jsonDecode(response.body);
          errorMsg = errJson['message'] ?? errJson['title'] ?? response.body;
        } catch (_) {}

        if (mounted) _showSnackBar("Lỗi: $errorMsg");
      }
    } catch (e) {
      if (mounted) _showSnackBar("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => isLoadingOrder = false);
    }
  }

  // Hàm tiện ích hiển thị thông báo
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Thành công", style: TextStyle(color: Colors.green)),
        content: const Text("Đơn hàng đã được tạo thành công!"),
        actions: [
          TextButton(
            onPressed: () {
              // Đóng dialog và quay về màn hình trước (hoặc Home)
              Navigator.of(ctx).pop(); // Đóng Dialog
              Navigator.of(ctx).pop(); // Quay về màn hình trước
            },
            child: const Text("OK", style: TextStyle(fontSize: 18)),
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
            // --- KHU VỰC CHỌN KHÁCH HÀNG ---
            isLoadingCustomers
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  )
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Chọn khách hàng",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    isExpanded: true,
                    value: selectedCustomerId,
                    hint: const Text("Vui lòng chọn khách hàng"),
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedCustomerId = val),
                  ),

            const SizedBox(height: 10),

            // --- NÚT XEM LỊCH SỬ ---
            if (selectedCustomerId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.history, color: Colors.blue),
                  label: const Text("Xem lịch sử & Công nợ"),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderHistoryScreen(customerId: selectedCustomerId!),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // --- CHỌN PHƯƠNG THỨC THANH TOÁN ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Phương thức thanh toán:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            RadioListTile(
              title: const Text("Tiền mặt"),
              subtitle: const Text("Thanh toán ngay"),
              value: "Cash",
              groupValue: selectedPaymentMethod,
              activeColor: Colors.green,
              onChanged: (val) =>
                  setState(() => selectedPaymentMethod = val.toString()),
            ),
            RadioListTile(
              title: const Text("Ghi nợ"),
              subtitle: const Text("Thêm vào công nợ khách hàng"),
              value: "Debt",
              groupValue: selectedPaymentMethod,
              activeColor: Colors.red,
              onChanged: (val) =>
                  setState(() => selectedPaymentMethod = val.toString()),
            ),

            const Spacer(),

            // --- NÚT TẠO ĐƠN HÀNG ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (isLoadingOrder ||
                        cart.items.isEmpty ||
                        selectedCustomerId == null)
                    ? null
                    : () => createOrder(cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: isLoadingOrder
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "XÁC NHẬN TẠO ĐƠN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
