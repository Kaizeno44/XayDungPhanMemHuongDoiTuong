// lib/checkout_screen.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // [MỚI] Riverpod
import 'package:http/http.dart' as http;

// [MỚI] Import Controller & Models
import 'package:bizflow_mobile/features/cart/cart_controller.dart';
import '../core/config/api_config.dart';
import '../models.dart';
import 'screens/invoice_preview_screen.dart';
import 'create_customer_dialog.dart';
import 'order_history_screen.dart';

// 1. Chuyển thành ConsumerStatefulWidget
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.storeId});

  final String storeId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  List<Customer> customers = [];
  String? selectedCustomerId;
  String selectedPaymentMethod = "Cash";
  bool isLoadingOrder = false;
  bool isLoadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  // --- 1. FETCH KHÁCH HÀNG (Giữ nguyên logic cũ) ---
  Future<void> _fetchCustomers() async {
    final url = Uri.parse(ApiConfig.customers);
    try {
      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is List) {
          if (mounted) {
            setState(() {
              customers = decodedData
                  .map((json) => Customer.fromJson(json))
                  .toList();
              isLoadingCustomers = false;
            });
          }
        } else {
          if (mounted) setState(() => isLoadingCustomers = false);
        }
      } else {
        if (mounted) setState(() => isLoadingCustomers = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingCustomers = false);
    }
  }

  // --- 2. TẠO ĐƠN HÀNG (Dùng Riverpod CartController) ---
  Future<void> createOrder() async {
    // [MỚI] Lấy dữ liệu giỏ hàng từ Riverpod
    final cartState = ref.read(cartControllerProvider);

    if (selectedCustomerId == null) {
      _showSnackBar("Vui lòng chọn khách hàng", isError: true);
      return;
    }
    if (cartState.items.isEmpty) {
      _showSnackBar("Giỏ hàng đang trống!", isError: true);
      return;
    }

    setState(() => isLoadingOrder = true);

    // Snapshot dữ liệu để hiển thị hóa đơn sau khi xóa giỏ hàng
    final itemsSnapshot = List<CartItem>.from(cartState.items);
    final totalSnapshot = cartState.totalAmount;

    // Tìm khách hàng đã chọn để lấy tên hiển thị
    final customerObj = customers.firstWhere(
      (c) => c.id == selectedCustomerId,
      orElse: () => Customer(id: '', name: 'Khách lẻ', phone: '', address: ''),
    );

    final url = Uri.parse(ApiConfig.orders);
    final requestBody = {
      "customerId": selectedCustomerId,
      "storeId": widget.storeId,
      "paymentMethod": selectedPaymentMethod,
      "items": cartState.items.map((e) => e.toJson()).toList(),
    };

    try {
      final response = await http
          .post(url, headers: ApiConfig.headers, body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // [QUAN TRỌNG] Xóa giỏ hàng thông qua Controller
        ref.read(cartControllerProvider.notifier).clearCart();

        if (mounted) {
          _showSuccessDialog(itemsSnapshot, totalSnapshot, customerObj.name);
        }
      } else {
        String errorMsg = response.body;
        try {
          final errJson = jsonDecode(response.body);
          if (errJson['errors'] != null) {
            errorMsg = errJson['errors'].toString();
          } else {
            errorMsg = errJson['message'] ?? errJson['title'] ?? response.body;
          }
        } catch (_) {}
        if (mounted) _showSnackBar("Lỗi: $errorMsg", isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Lỗi kết nối: $e", isError: true);
    } finally {
      if (mounted) setState(() => isLoadingOrder = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showSuccessDialog(
    List<CartItem> items,
    double total,
    String customerName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text(
              "Thành công",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Đơn hàng đã tạo!\nBạn có muốn in hoặc chia sẻ hóa đơn không?",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Đóng dialog
              Navigator.of(context).pop(); // Về màn hình Cart
              Navigator.of(context).pop(); // Về màn hình Home (nếu cần)
            },
            child: const Text("Đóng"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.print, size: 18),
            label: const Text("In / Share"),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePreviewScreen(
                    items: items,
                    customerName: customerName,
                    paymentMethod: selectedPaymentMethod,
                    totalAmount: total,
                    storeId: widget.storeId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe số lượng items để hiển thị trên nút xác nhận
    final cartState = ref.watch(cartControllerProvider);
    final itemCount = cartState.items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- KHU VỰC CHỌN KHÁCH HÀNG ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: isLoadingCustomers
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Chọn khách hàng",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 16,
                            ),
                          ),
                          isExpanded: true,
                          value:
                              selectedCustomerId, // Fix: Dùng value thay vì initialValue
                          hint: const Text("Chọn khách hàng..."),
                          items: customers
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    "${c.name} - ${c.phone}",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedCustomerId = val),
                        ),
                ),

                const SizedBox(width: 8),

                // NÚT THÊM NHANH KHÁCH HÀNG
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    tooltip: "Thêm khách mới",
                    onPressed: () async {
                      final newCustomer = await showDialog<Customer>(
                        context: context,
                        builder: (_) =>
                            CreateCustomerDialog(storeId: widget.storeId),
                      );

                      if (newCustomer != null) {
                        setState(() {
                          customers.add(newCustomer);
                          selectedCustomerId = newCustomer.id;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Nút xem lịch sử (Chỉ hiện khi đã chọn khách)
            if (selectedCustomerId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.history, color: Colors.blue),
                  label: const Text("Xem lịch sử & Công nợ"),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
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

            // Chọn phương thức thanh toán
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
              secondary: const Icon(Icons.money, color: Colors.green),
              onChanged: (val) =>
                  setState(() => selectedPaymentMethod = val.toString()),
            ),
            RadioListTile(
              title: const Text("Ghi nợ"),
              subtitle: const Text("Thêm vào công nợ"),
              value: "Debt",
              groupValue: selectedPaymentMethod,
              activeColor: Colors.red,
              secondary: const Icon(
                Icons.account_balance_wallet,
                color: Colors.red,
              ),
              onChanged: (val) =>
                  setState(() => selectedPaymentMethod = val.toString()),
            ),

            const Spacer(),

            // Nút Xác Nhận
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (isLoadingOrder ||
                        itemCount == 0 ||
                        selectedCustomerId == null)
                    ? null
                    : createOrder, // Gọi hàm createOrder mới
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoadingOrder
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        "XÁC NHẬN TẠO ĐƠN ($itemCount món)",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
