import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:bizflow_mobile/pay_debt_screen.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';
// import 'package:bizflow_mobile/core/config/api_config.dart'; // Uncomment nếu dùng file config

class OrderHistoryScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const OrderHistoryScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dữ liệu
  List<dynamic> _orders = [];
  List<dynamic> _debtLogs = [];
  double _currentDebt = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- GỌI API LẤY DỮ LIỆU ---
  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lưu ý: Cập nhật IP/Port cho đúng với Backend của bạn
      final baseUrl = "http://10.0.2.2:5103/api/Customers/${widget.customerId}";

      // Gọi song song 2 API
      final results = await Future.wait([
        http.get(
          Uri.parse("$baseUrl/history"),
        ), // 1. Lịch sử đơn hàng + Tổng nợ
        http.get(Uri.parse("$baseUrl/debt-logs")), // 2. Lịch sử biến động nợ
      ]);

      final historyRes = results[0];
      final logsRes = results[1];

      if (historyRes.statusCode == 200) {
        final historyData = jsonDecode(historyRes.body);
        setState(() {
          _orders = historyData['orders'] ?? [];
          _currentDebt = (historyData['currentDebt'] ?? 0).toDouble();
        });
      } else {
        _errorMessage = "Lỗi tải đơn hàng: ${historyRes.statusCode}";
      }

      if (logsRes.statusCode == 200) {
        final logsData = jsonDecode(logsRes.body);
        setState(() {
          _debtLogs = logsData is List ? logsData : [];
        });
      }

      // Nếu cả 2 API đều fail thì mới báo lỗi chung, còn không thì vẫn hiện cái nào lấy được
      if (historyRes.statusCode != 200 && logsRes.statusCode != 200) {
        _errorMessage = "Không thể tải dữ liệu";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối: $e";
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName, style: const TextStyle(fontSize: 18)),
            const Text(
              "Chi tiết khách hàng",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- CARD TỔNG NỢ (Sticky Header) ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Nợ hiện tại",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(_currentDebt),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _currentDebt > 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentDebt <= 0
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PayDebtScreen(
                                      customerId: widget.customerId,
                                      customerName: widget.customerName,
                                      storeId:
                                          authProvider.currentUser?.storeId ??
                                          "",
                                      currentDebt: _currentDebt,
                                    ),
                                  ),
                                );
                                // Reload lại dữ liệu nếu có thanh toán
                                if (result == true) _fetchAllData();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text("Thanh toán"),
                      ),
                    ],
                  ),
                ),

                // --- TAB CONTENT ---
                Expanded(
                  child: _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // TAB 1: DANH SÁCH ĐƠN HÀNG
                            _buildOrderList(currencyFormat),

                            // TAB 2: LỊCH SỬ BIẾN ĐỘNG NỢ
                            _buildDebtLogList(currencyFormat),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  // --- WIDGET: DANH SÁCH ĐƠN HÀNG ---
  Widget _buildOrderList(NumberFormat currencyFormat) {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("Chưa có đơn hàng nào", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final isDebt = order['paymentMethod'] == 'Debt';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_outlined, color: Colors.blue),
              ),
              title: Text(
                "#${order['orderCode'] ?? '---'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(DateTime.parse(order['orderDate'])),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(order['totalAmount']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDebt
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isDebt ? 'Ghi nợ' : 'Tiền mặt',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDebt ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET: LỊCH SỬ BIẾN ĐỘNG NỢ ---
  Widget _buildDebtLogList(NumberFormat currencyFormat) {
    if (_debtLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_edu, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Chưa có giao dịch nợ nào",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _debtLogs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final log = _debtLogs[index];
          final isPayment = log['action'] == 'Payment'; // True nếu là trả tiền
          final amount = (log['amount'] as num).toDouble();

          return Card(
            elevation: 0,
            color: isPayment ? Colors.green.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isPayment ? Colors.green.shade200 : Colors.grey.shade200,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPayment ? Colors.green : Colors.red,
                radius: 18,
                child: Icon(
                  isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(
                isPayment ? "Thanh toán nợ" : "Mua hàng ghi nợ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPayment ? Colors.green[800] : Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(DateTime.parse(log['timestamp'])),
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (log['note'] != null && log['note'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "📝 ${log['note']}",
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isPayment ? '' : '+'}${currencyFormat.format(amount)}", // Payment đã âm sẵn ở BE hoặc tùy logic
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isPayment ? Colors.green[700] : Colors.red,
                    ),
                  ),
                  // Nếu Backend trả về NewDebtSnapshot thì hiển thị, ko thì ẩn
                  if (log['newDebtSnapshot'] != null)
                    Text(
                      "Dư nợ: ${currencyFormat.format(log['newDebtSnapshot'])}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
