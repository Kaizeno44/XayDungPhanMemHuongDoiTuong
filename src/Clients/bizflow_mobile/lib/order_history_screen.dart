import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'pay_debt_screen.dart'; // 👈 Màn hình Trả nợ

class OrderHistoryScreen extends StatefulWidget {
  final String customerId;

  const OrderHistoryScreen({super.key, required this.customerId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> orders = [];
  double currentDebt = 0;
  bool isLoading = true;
  String? errorMessage;

  // Hardcode StoreId giống CheckoutScreen
  final String storeId = "3fa85f64-5717-4562-b3fc-2c963f66afa6";

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  // =========================
  // GỌI API LỊCH SỬ + CÔNG NỢ
  // =========================
  Future<void> fetchHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url =
        "http://10.0.2.2:5103/api/Customers/${widget.customerId}/history";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orders = data['orders'];
          currentDebt = (data['currentDebt'] as num).toDouble();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Lỗi Server: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Không thể kết nối Server.\nVui lòng kiểm tra Backend.";
      });
    }
  }

  // =========================
  // MÀU TRẠNG THÁI
  // =========================
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Pending':
        return 'Chờ xử lý';
      case 'Cancelled':
        return 'Đã hủy';
      case 'Completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử & Công nợ"),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // =========================
                // PHẦN TỔNG NỢ + NÚT TRẢ NỢ
                // =========================
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tổng dư nợ hiện tại",
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(currentDebt),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payments),
                        label: const Text("Trả nợ"),
                        onPressed: currentDebt <= 0
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PayDebtScreen(
                                      customerId: widget.customerId,
                                      storeId: storeId,
                                      currentDebt: currentDebt,
                                    ),
                                  ),
                                );

                                // Nếu trả nợ OK → reload
                                if (result == true) {
                                  fetchHistory();
                                }
                              },
                      ),
                    ],
                  ),
                ),

                // =========================
                // DANH SÁCH ĐƠN HÀNG
                // =========================
                Expanded(
                  child: errorMessage != null
                      ? Center(
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchHistory,
                          child: orders.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 10),
                                          Text("Chưa có đơn hàng nào"),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: orders.length,
                                  itemBuilder: (ctx, i) {
                                    final order = orders[i];
                                    final statusColor = _getStatusColor(
                                      order['status'],
                                    );

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  order['orderCode'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  _translateStatus(
                                                    order['status'],
                                                  ),
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(),
                                            Text(
                                              "Ngày: ${dateFormat.format(DateTime.parse(order['orderDate']))}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Thanh toán: ${order['paymentMethod'] == 'Debt' ? 'Ghi nợ' : 'Tiền mặt'}",
                                            ),
                                            const SizedBox(height: 6),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                currencyFormat.format(
                                                  order['totalAmount'],
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
    );
  }
}
