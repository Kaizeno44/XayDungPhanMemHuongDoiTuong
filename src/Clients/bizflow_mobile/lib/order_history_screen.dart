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

  // Hàm tải dữ liệu (Đã hỗ trợ Pull-to-refresh)
  Future<void> _refreshData() async {
    // Chỉ hiện loading xoay xoay khi dữ liệu đang trống
    if (_orders.isEmpty && _debtLogs.isEmpty) {
      setState(() => _isLoading = true);
    }

    final userState = ref.read(authNotifierProvider);
    final storeId = userState.currentUser?.storeId;

    if (storeId == null || storeId.isEmpty) return;

    try {
      // Gọi song song 3 API
      final results = await Future.wait([
        _orderService.getOrdersByCustomer(widget.customerId),
        _orderService.getDebtHistory(widget.customerId),
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
        // Sắp xếp đơn mới nhất lên đầu
        _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        _debtLogs = debtLogs;
        // Sắp xếp lịch sử mới nhất lên đầu
        _debtLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _currentDebt = currentCustomer.currentDebt;
        _isLoading = false;
        _debugMessage = ""; // Xóa thông báo lỗi nếu tải thành công
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

  // [CẢI TIẾN 2] Hàm hiển thị chi tiết đơn hàng (Popup)
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
                      // Nếu muốn hiển thị danh sách sản phẩm chi tiết, bạn cần gọi thêm API lấy OrderItem ở đây
                      // Hiện tại tạm thời hiển thị tổng tiền
                      const Divider(),
                      _buildDetailRow(
                        "TỔNG TIỀN",
                        NumberFormat(
                              "#,##0",
                              "vi_VN",
                            ).format(order.totalAmount) +
                            " đ",
                        isBold: true,
                        color: Colors.blue[800],
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
              backgroundColor: Colors.red,
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text(
                "Thu Nợ Ngay",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                      // [CẢI TIẾN 1] Bọc danh sách trong RefreshIndicator
                      RefreshIndicator(
                        onRefresh: _refreshData,
                        child: _buildOrderList(currencyFormat),
                      ),
                      RefreshIndicator(
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
          const Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey,
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
              vertical: 4,
            ),
            // Sự kiện Click xem chi tiết
            onTap: () => _showOrderDetail(order),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.receipt, color: Colors.blue[800], size: 20),
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

  // Widget Lịch Sử Nợ
  Widget _buildDebtLogList(NumberFormat fmt) {
    if (_debtLogs.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Center(
            child: Icon(Icons.history, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Chưa có lịch sử nợ",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _debtLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final log = _debtLogs[i];
        // [CẢI TIẾN 3] Phân biệt màu sắc rõ ràng
        final isCredit =
            log.action == 'Credit' ||
            log.action == 'Payment' ||
            log.action == 'Thu nợ';

        return Card(
          elevation: 0,
          color: isCredit
              ? Colors.green.withOpacity(0.05)
              : Colors.red.withOpacity(0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isCredit
                ? BorderSide(color: Colors.green.withOpacity(0.3))
                : BorderSide(color: Colors.red.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: isCredit ? Colors.green : Colors.red,
              radius: 18,
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(
              isCredit ? "Khách trả tiền" : "Ghi nợ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.reason.isNotEmpty)
                  Text(
                    log.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: Text(
              "${isCredit ? '-' : '+'}${fmt.format(log.amount)} đ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}