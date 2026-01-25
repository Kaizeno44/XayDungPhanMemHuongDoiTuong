import 'package:bizflow_mobile/models.dart';
import 'package:bizflow_mobile/order_history_screen.dart';
import 'package:bizflow_mobile/providers/auth_provider.dart';
import 'package:bizflow_mobile/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sắp xếp: Ai nợ đưa lên đầu, sau đó mới đến người không nợ
    final filteredList = _allCustomers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList()..sort((a, b) => b.currentDebt.compareTo(a.currentDebt));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sổ Nợ"),
        // ✅ BỎ: backgroundColor: Colors.white (Để nó tự ăn theo Theme Cam)
        // ✅ BỎ: foregroundColor: Colors.black
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: "Sắp xếp",
            onPressed: () {
              // Có thể thêm logic filter nâng cao ở đây
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100], // Nền xám nhẹ làm nổi bật thẻ
      body: Column(
        children: [
          // --- THANH TÌM KIẾM ---
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).primaryColor, // Nền cam phần trên
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm tên hoặc số điện thoại...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Không tìm thấy khách hàng",
                          style: TextStyle(color: Colors.grey),
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
                        final hasDebt = customer.currentDebt > 0;

                        return _buildCustomerCard(customer, hasDebt);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, bool hasDebt) {
    return Card(
      elevation: hasDebt ? 3 : 1, // Card nợ nổi hơn chút
      shadowColor: hasDebt ? Colors.red.withOpacity(0.2) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Viền đỏ nhẹ nếu có nợ, không viền nếu sạch
        side: hasDebt
            ? BorderSide(color: Colors.red.shade100, width: 1)
            : BorderSide.none,
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
          _fetchCustomers();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // --- AVATAR ---
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hasDebt ? Colors.red.shade50 : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasDebt
                      ? Icons.history_edu
                      : Icons.check_circle_outline, // Icon ý nghĩa hơn
                  color: hasDebt ? Colors.red : Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // --- THÔNG TIN ---
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone.isNotEmpty
                          ? customer.phone
                          : "Chưa có SĐT",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),

              // --- SỐ TIỀN ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDebt) ...[
                    Text(
                      "ĐANG NỢ",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${_currencyFormat.format(customer.currentDebt)} đ",
                      style: const TextStyle(
                        color: Colors.red, // Màu đỏ cảnh báo
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Sạch nợ",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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
