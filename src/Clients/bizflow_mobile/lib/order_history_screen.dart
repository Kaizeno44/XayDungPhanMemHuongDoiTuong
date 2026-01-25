import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizflow_mobile/pay_debt_screen.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;

  const OrderHistoryScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _orders = [];
  List<dynamic> _debtLogs = [];
  double _currentDebt = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAllData());
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final baseUrl = "http://10.0.2.2:5103/api/Customers/${widget.customerId}";
      final results = await Future.wait([
        http.get(Uri.parse("$baseUrl/history")),
        http.get(Uri.parse("$baseUrl/debt-logs")),
      ]);

      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body);
        if (mounted)
          setState(() {
            _orders = data['orders'] ?? [];
            _currentDebt = (data['currentDebt'] ?? 0).toDouble();
          });
      }
      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body);
        if (mounted) setState(() => _debtLogs = data is List ? data : []);
      }
    } catch (e) {
      if (mounted) _errorMessage = "Lỗi kết nối: $e";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "vi_VN");
    final userState = ref.watch(authNotifierProvider);
    final storeId = userState.currentUser?.storeId ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName, style: const TextStyle(fontSize: 18)),
            const Text(
              "Chi tiết & Lịch sử",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Đơn Hàng", icon: Icon(Icons.shopping_bag_outlined)),
            Tab(text: "Lịch Sử Nợ", icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      // Nút thanh toán nổi (Floating Action Button) - UX tiện hơn
      floatingActionButton: _currentDebt > 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PayDebtScreen(
                      customerId: widget.customerId,
                      storeId: storeId,
                      currentDebt: _currentDebt,
                    ),
                  ),
                );
                if (result == true) _fetchAllData();
              },
              backgroundColor: Colors.red,
              icon: const Icon(Icons.payment),
              label: const Text("Thu Nợ Ngay"),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thẻ tổng quan nợ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Text(
                        "Tổng nợ hiện tại",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${currencyFormat.format(_currentDebt)} đ",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _currentDebt > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(currencyFormat), // Tab 1
                      _buildDebtLogList(currencyFormat), // Tab 2
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Widget: List Đơn hàng (Giữ nguyên logic cũ nhưng làm gọn code)
  Widget _buildOrderList(NumberFormat fmt) {
    if (_orders.isEmpty)
      return const Center(
        child: Text("Chưa có đơn hàng", style: TextStyle(color: Colors.grey)),
      );
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final o = _orders[i];
        final isDebt = o['paymentMethod'] == 'Debt';
        return Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(Icons.receipt, color: Colors.blue[800]),
            title: Text(
              "#${o['orderCode'] ?? '---'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(DateTime.parse(o['orderDate'])),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${fmt.format(o['totalAmount'])} đ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isDebt ? "Ghi nợ" : "Tiền mặt",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDebt ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget: List Lịch sử nợ
  Widget _buildDebtLogList(NumberFormat fmt) {
    if (_debtLogs.isEmpty)
      return const Center(
        child: Text(
          "Chưa có giao dịch nợ",
          style: TextStyle(color: Colors.grey),
        ),
      );
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _debtLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final log = _debtLogs[i];
        final isPayment = log['action'] == 'Payment';
        return Card(
          elevation: 0,
          color: isPayment ? Colors.green[50] : Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPayment ? Colors.green : Colors.red,
              child: Icon(
                isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(
              isPayment ? "Thanh toán" : "Ghi nợ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(DateTime.parse(log['timestamp'])),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isPayment ? '-' : '+'}${fmt.format(log['amount'])}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPayment ? Colors.green : Colors.red,
                  ),
                ),
                if (log['newDebtSnapshot'] != null)
                  Text(
                    "Dư: ${fmt.format(log['newDebtSnapshot'])}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
