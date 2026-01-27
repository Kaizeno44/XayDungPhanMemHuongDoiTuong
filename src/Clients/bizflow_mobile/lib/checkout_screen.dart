import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:bizflow_mobile/features/cart/cart_controller.dart';
import 'package:bizflow_mobile/core/config/api_config.dart';
import 'package:bizflow_mobile/models.dart';
import 'package:bizflow_mobile/screens/invoice_preview_screen.dart';
import 'package:bizflow_mobile/screens/create_customer_dialog.dart';

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
              
              // FIX: Kiểm tra xem ID đang chọn có còn tồn tại trong list mới không
              // Nếu không thì reset về null để tránh crash Dropdown
              if (selectedCustomerId != null) {
                final exists = customers.any((c) => c.id == selectedCustomerId);
                if (!exists) {
                  selectedCustomerId = null;
                }
              }
              
              isLoadingCustomers = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => isLoadingCustomers = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingCustomers = false);
      debugPrint("Error fetching customers: $e");
    }
  }

  Future<void> createOrder() async {
    final cartState = ref.read(cartControllerProvider);

    // 1. Validate
    if (selectedCustomerId == null) {
      _showSnackBar("Vui lòng chọn khách hàng", isError: true);
      return;
    }
    if (cartState.items.isEmpty) {
      _showSnackBar("Giỏ hàng đang trống!", isError: true);
      return;
    }

    setState(() => isLoadingOrder = true);

    // Snapshot dữ liệu để hiển thị Dialog sau khi clear giỏ hàng
    final itemsSnapshot = List<CartItem>.from(cartState.items);
    final totalSnapshot = cartState.totalAmount;
    
    // FIX: Sử dụng selectedCustomerId! an toàn vì đã check null ở trên
    final currentCustId = selectedCustomerId!; 

    // Lấy tên khách hàng
    final customerObj = customers.firstWhere(
      (c) => c.id == currentCustId,
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
      "customerId": currentCustId,
      "storeId": widget.storeId,
      "paymentMethod": selectedPaymentMethod,
      "items": cartState.items.map((e) => e.toJson()).toList(),
    };

    try {
      final response = await http
          .post(
            url, 
            // Đảm bảo ApiConfig.headers có 'Content-Type': 'application/json'
            headers: ApiConfig.headers, 
            body: jsonEncode(requestBody)
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear giỏ hàng trước
        ref.read(cartControllerProvider.notifier).clearCart();

        if (mounted) {
          _showSuccessDialog(itemsSnapshot, totalSnapshot, customerObj.name);
        }
      } else {
        String errorMsg = "Tạo đơn thất bại";
        try {
          final errJson = jsonDecode(response.body);
          if (errJson['errors'] != null) {
            errorMsg = errJson['errors'].toString();
          } else if (errJson['message'] != null) {
            errorMsg = errJson['message'];
          } else if (errJson['title'] != null) {
            errorMsg = errJson['title'];
          }
        } catch (_) {
          errorMsg = response.body;
        }
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
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 12),
            Text(
              "Đặt hàng thành công!",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Đơn hàng đã được lưu vào hệ thống.\nBạn có muốn in hóa đơn ngay không?",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Đóng Dialog
              Navigator.of(context).pop(); // Đóng màn hình Checkout (về trang chủ/bán hàng)
            },
            child: const Text("Đóng"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.print, size: 18),
            label: const Text("In Hóa Đơn"),
            onPressed: () {
              Navigator.of(ctx).pop(); // Đóng Dialog
              // Chuyển sang màn hình In
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. CHỌN KHÁCH HÀNG ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: isLoadingCustomers
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Khách hàng",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          isExpanded: true,
                          // FIX: Đảm bảo value null hoặc phải có trong list items
                          value: (selectedCustomerId != null && 
                                  customers.any((c) => c.id == selectedCustomerId)) 
                                  ? selectedCustomerId 
                                  : null,
                          hint: const Text("Chọn khách hàng..."),
                          items: customers.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                "${c.name} - ${c.phone}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedCustomerId = val);
                          },
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
                        _showSnackBar("Đã thêm khách hàng mới!");
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // --- 2. PHƯƠNG THỨC THANH TOÁN ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Phương thức thanh toán",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Radio Tiền mặt
            _buildPaymentMethodRadio("Cash", "Tiền mặt", "Thanh toán ngay khi nhận hàng", Icons.monetization_on, Colors.green),
            
            // Radio Ghi nợ
            _buildPaymentMethodRadio("Debt", "Ghi nợ", "Lưu vào sổ nợ khách hàng", Icons.account_balance_wallet, Colors.red),

            const SizedBox(height: 40),

            // --- 3. NÚT SUBMIT ---
            SizedBox(
              width: double.infinity,
              height: 54,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isLoadingOrder
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          Text(
                            "XÁC NHẬN TẠO ĐƠN ($itemCount SP)",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tách Widget Radio để code gọn hơn
  Widget _buildPaymentMethodRadio(String value, String title, String subtitle, IconData icon, Color color) {
    final isSelected = selectedPaymentMethod == value;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? color.withOpacity(0.05) : null,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        value: value,
        groupValue: selectedPaymentMethod,
        activeColor: color,
        secondary: Icon(icon, color: color),
        onChanged: (val) =>
            setState(() => selectedPaymentMethod = val.toString()),
      ),
    );
  }
}