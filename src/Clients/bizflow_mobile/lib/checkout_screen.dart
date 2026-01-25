import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:bizflow_mobile/features/cart/cart_controller.dart';
import 'package:bizflow_mobile/core/config/api_config.dart';
import 'package:bizflow_mobile/models.dart';
import 'package:bizflow_mobile/screens/invoice_preview_screen.dart';
import 'package:bizflow_mobile/screens/create_customer_dialog.dart'; // Đảm bảo import đúng

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

  Future<void> _fetchCustomers() async {
    final url = Uri.parse(
      ApiConfig.customers,
    ).replace(queryParameters: {'storeId': widget.storeId});

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

  Future<void> createOrder() async {
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

    final itemsSnapshot = List<CartItem>.from(cartState.items);
    final totalSnapshot = cartState.totalAmount;

    // Lấy tên khách hàng để hiển thị hóa đơn
    final customerObj = customers.firstWhere(
      (c) => c.id == selectedCustomerId,
      orElse: () => Customer(
        id: '',
        name: 'Khách lẻ',
        phone: '',
        address: '',
        currentDebt: 0,
      ),
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
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
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
                          value: selectedCustomerId,
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

            // ĐÃ XÓA NÚT "XEM LỊCH SỬ & CÔNG NỢ" Ở ĐÂY
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
                    : createOrder,
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
