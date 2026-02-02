import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bizflow_mobile/models.dart';
import 'package:bizflow_mobile/order_service.dart';
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
  final _orderService = OrderService();

  List<Order> _orders = [];
  List<DebtLog> _debtLogs = [];
  double _currentDebt = 0;
  bool _isLoading = true;
  String _debugMessage = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  // Hàm tải dữ liệu
  Future<void> _refreshData() async {
    if (_orders.isEmpty && _debtLogs.isEmpty) {
      setState(() => _isLoading = true);
    }

    final userState = ref.read(authNotifierProvider);
    final storeId = userState.currentUser?.storeId;

    if (storeId == null || storeId.isEmpty) return;

    try {
      final results = await Future.wait([
        _orderService.getOrdersByCustomer(widget.customerId, storeId: storeId),
        _orderService.getDebtHistory(widget.customerId, storeId: storeId),
        _orderService.getCustomers(storeId: storeId),
      ]);

      if (!mounted) return;

      final orders = results[0] as List<Order>;
      final debtLogs = results[1] as List<DebtLog>;
      final customers = results[2] as List<Customer>;

      final currentCustomer = customers.firstWhere(
        (c) => c.id == widget.customerId,
        orElse: () => Customer(id: '', name: '', currentDebt: 0),
      );

      setState(() {
        _orders = orders;
        _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        _debtLogs = debtLogs;
        _debtLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _currentDebt = currentCustomer.currentDebt;
        _isLoading = false;
        _debugMessage = "";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _debugMessage = "Có lỗi khi tải dữ liệu: $e";
        });
      }
    }
  }

  // Hiển thị chi tiết đơn hàng
  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  "Chi tiết đơn #${order.orderCode}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDetailRow(
                        "Ngày đặt",
                        DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
                      ),
                      _buildDetailRow(
                        "Trạng thái",
                        order.status == "Confirmed"
                            ? "Đã hoàn thành"
                            : order.status,
                      ),
                      _buildDetailRow(
                        "Thanh toán",
                        order.paymentMethod == "Debt" ? "Ghi nợ" : "Tiền mặt",
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      _buildDetailRow(
                        "TỔNG TIỀN",
                        NumberFormat(
                              "#,##0",
                              "vi_VN",
                            ).format(order.totalAmount) +
                            " đ",
                        isBold: true,
                        // [THEME] Màu cam chủ đạo
                        color: Colors.orange[800],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
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
              "Lịch sử giao dịch",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        // [THEME] AppBar màu cam
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Đơn Hàng", icon: Icon(Icons.shopping_bag_outlined)),
            Tab(text: "Lịch Sử Nợ", icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),

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
                if (result == true) _refreshData();
              },
              // [THEME] Nút màu cam
              backgroundColor: Colors.orange[800],
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text(
                "Thu Nợ Ngay",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,

      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange[800]))
          : Column(
              children: [
                if (_debugMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.orange.shade100,
                    child: Text(
                      _debugMessage,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Header Tổng Nợ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Tổng nợ hiện tại",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
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

                // Body chứa TabView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        color: Colors.orange[800],
                        onRefresh: _refreshData,
                        child: _buildOrderList(currencyFormat),
                      ),
                      RefreshIndicator(
                        color: Colors.orange[800],
                        onRefresh: _refreshData,
                        child: _buildDebtLogList(currencyFormat),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Widget Danh sách Đơn Hàng
  Widget _buildOrderList(NumberFormat fmt) {
    if (_orders.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Chưa có đơn hàng nào",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final order = _orders[i];
        final isDebt = order.paymentMethod == 'Debt';
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
            onTap: () => _showOrderDetail(order),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // [THEME] Nền icon cam nhạt
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                // [THEME] Icon màu cam đậm
                color: Colors.orange[800],
                size: 20,
              ),
            ),
            title: Text(
              order.orderCode.isNotEmpty ? "#${order.orderCode}" : "Đơn hàng",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${fmt.format(order.totalAmount)} đ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDebt
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isDebt ? "Ghi nợ" : "Tiền mặt",
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
    );
  }

  // Widget Lịch Sử Nợ (Đã cải tiến UX với màu Xanh Dương)
  Widget _buildDebtLogList(NumberFormat fmt) {
    if (_debtLogs.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(child: Icon(Icons.history, size: 64, color: Colors.grey[300])),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Chưa có lịch sử ghi nợ nào",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _debtLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final log = _debtLogs[i];

        // Xác định loại giao dịch
        // Credit/Payment/Thu nợ -> Tiền vào -> Giảm nợ -> Màu Xanh Dương (Blue)
        final isPayment =
            log.action == 'Credit' ||
            log.action == 'Payment' ||
            log.action == 'Thu nợ';

        return Card(
          elevation: 0,
          // Màu nền: Trả tiền (Xanh dương nhạt) vs Ghi nợ (Đỏ nhạt)
          color: isPayment
              ? Colors.blue.withOpacity(0.05)
              : Colors.red.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPayment
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 1. Icon Mũi tên ngược hướng
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPayment
                        ? Colors.blue.shade100
                        : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    // Trả tiền: Mũi tên xuống (Giảm nợ/Tiền về)
                    // Ghi nợ: Mũi tên lên (Tăng nợ)
                    isPayment
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isPayment ? Colors.blue[700] : Colors.red[700],
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // 2. Nội dung text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPayment ? "Khách trả tiền" : "Ghi nợ đơn hàng",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isPayment ? Colors.blue[800] : Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy • HH:mm').format(log.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      // Hiển thị lý do nếu có
                      if (log.reason.isNotEmpty && log.reason != "Payment")
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Note: ${log.reason}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // 3. Số tiền (Thêm dấu +/-)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      // Trả tiền thì TRỪ nợ (-), Ghi nợ thì CỘNG nợ (+)
                      "${isPayment ? '-' : '+'}${fmt.format(log.amount)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isPayment ? Colors.blue[700] : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "VNĐ",
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
