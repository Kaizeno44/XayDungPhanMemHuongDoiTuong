import 'dart:convert';
import 'dart:async'; // Cần cho Timeout
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'core/config/api_config.dart'; // Import config chuẩn
import 'cart_provider.dart';
import 'models.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.customerId,
    required this.storeId,
  });

  final String customerId;
  final String storeId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Biến lưu danh sách khách hàng
  List<Customer> customers = [];

  // Các biến trạng thái
  String? selectedCustomerId;
  String selectedPaymentMethod = "Cash";
  bool isLoadingOrder = false;
  bool isLoadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  // --- 1. LẤY KHÁCH HÀNG (AN TOÀN & CHUẨN CONFIG) ---
  Future<void> _fetchCustomers() async {
    // Sử dụng đường dẫn từ ApiConfig (Port 5103)
    final url = Uri.parse(ApiConfig.customers);

    try {
      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 1. Giải mã JSON an toàn (dynamic)
        final dynamic decodedData = jsonDecode(response.body);

        // 2. Kiểm tra cấu trúc dữ liệu để tránh Crash
        if (decodedData is List) {
          setState(() {
            customers = decodedData
                .map(
                  (json) => Customer(
                    // Ép kiểu ID về String để an toàn
                    id: json['id'].toString(),
                    // Ưu tiên fullName, nếu không có thì lấy name, fallback "Ẩn danh"
                    name:
                        json['fullName'] ??
                        json['name'] ??
                        "Khách hàng ẩn danh",
                  ),
                )
                .toList();
            isLoadingCustomers = false;
          });
        } else {
          // Nếu API trả về Object (ví dụ báo lỗi hoặc wrap data), log lại và không crash
          debugPrint("⚠️ API trả về không phải List: $decodedData");
          if (mounted) _showSnackBar("Dữ liệu khách hàng sai định dạng.");
          setState(() => isLoadingCustomers = false);
        }
      } else {
        _showSnackBar("Lỗi tải khách hàng: ${response.statusCode}");
        setState(() => isLoadingCustomers = false);
      }
    } catch (e) {
      debugPrint("🔴 Lỗi kết nối: $e");
      _showSnackBar("Không thể kết nối Server.");
      setState(() => isLoadingCustomers = false);
    }
  }

  // --- 2. TẠO ĐƠN HÀNG (CHUẨN CONFIG) ---
  Future<void> createOrder(CartProvider cart) async {
    if (selectedCustomerId == null) {
      _showSnackBar("Vui lòng chọn khách hàng");
      return;
    }

    setState(() => isLoadingOrder = true);

    // Sử dụng đường dẫn từ ApiConfig
    final url = Uri.parse(ApiConfig.orders);

    final requestBody = {
      "customerId": selectedCustomerId,
      "storeId": widget.storeId, // Dùng storeId truyền vào từ widget
      "paymentMethod": selectedPaymentMethod,
      "items": cart.items.map((e) => e.toJson()).toList(),
    };

    try {
      final response = await http
          .post(
            url,
            headers: ApiConfig.headers, // Dùng header chuẩn
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        cart.clearCart();
        if (mounted) _showSuccessDialog();
      } else {
        // Parse lỗi từ Server trả về cho đẹp
        String errorMsg = response.body;
        try {
          final errJson = jsonDecode(response.body);
          errorMsg = errJson['message'] ?? errJson['title'] ?? response.body;
        } catch (_) {}
        if (mounted) _showSnackBar("Lỗi tạo đơn: $errorMsg");
      }
    } catch (e) {
      if (mounted) _showSnackBar("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => isLoadingOrder = false);
    }
  }

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
