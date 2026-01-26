import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import 'package:bizflow_mobile/models.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';
import 'package:bizflow_mobile/order_service.dart';
import 'package:bizflow_mobile/order_history_screen.dart'; // Đảm bảo import đúng đường dẫn

class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  final _orderService = OrderService();
  final _currencyFormat = NumberFormat("#,##0", "vi_VN");

  String _searchQuery = "";
  List<Customer> _allCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Gọi API ngay khi màn hình load xong
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCustomers());
  }

  Future<void> _fetchCustomers() async {
    final userState = ref.read(authNotifierProvider);
    final storeId = userState.currentUser?.storeId;

    if (storeId == null || storeId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final customers = await _orderService.getCustomers(storeId: storeId);
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Lỗi tải khách hàng: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Logic lọc & Sắp xếp (Người nợ nhiều lên đầu)
    final filteredList = _allCustomers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList()..sort((a, b) => b.currentDebt.compareTo(a.currentDebt));

    // 2. Tính tổng nợ hiển thị
    final totalDebt = filteredList.fold(
      0.0,
      (sum, item) => sum + item.currentDebt,
    );

    return GestureDetector(
      // [UX] Chạm ra ngoài để ẩn bàn phím
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Sổ Nợ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          // [THEME] Đồng bộ màu Cam đậm
          backgroundColor: Colors.orange[800],
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Tải lại",
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchCustomers();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // --- HEADER: TÌM KIẾM & TỔNG KẾT ---
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: BoxDecoration(
                color: Colors.orange[800], // Màu nền liền mạch với AppBar
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Thanh tìm kiếm
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Tìm tên, số điện thoại...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 20),

                  // Thống kê tổng nợ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Tổng nợ cần thu:",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                      Text(
                        "${_currencyFormat.format(totalDebt)} đ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- DANH SÁCH KHÁCH HÀNG ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Không tìm thấy khách hàng nào",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchCustomers,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = filteredList[index];
                          return _buildCustomerCard(customer);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final hasDebt = customer.currentDebt > 0;

    return Card(
      elevation: hasDebt ? 2 : 0,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasDebt
            ? BorderSide(color: Colors.red.shade100, width: 1)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderHistoryScreen(
                customerId: customer.id,
                customerName: customer.name,
              ),
            ),
          );
          _fetchCustomers(); // Refresh lại sau khi quay về
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasDebt ? Colors.red[50] : Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : "?",
                    style: TextStyle(
                      color: hasDebt ? Colors.red[700] : Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone.isNotEmpty ? customer.phone : "---",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Debt Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDebt) ...[
                    Text(
                      "${_currencyFormat.format(customer.currentDebt)} đ",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Chưa thanh toán",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "0 đ",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Sạch nợ",
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}
