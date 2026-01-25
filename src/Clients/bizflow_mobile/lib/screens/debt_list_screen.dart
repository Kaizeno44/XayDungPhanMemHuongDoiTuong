import 'package:bizflow_mobile/models.dart';
import 'package:bizflow_mobile/order_history_screen.dart'; // Import màn hình chi tiết
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
    final filteredList = _allCustomers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sổ Nợ"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm khách hàng...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(
                    child: Text(
                      "Không tìm thấy khách hàng",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchCustomers,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final customer = filteredList[index];
                        final hasDebt = customer.currentDebt > 0;

                        return Card(
                          elevation: hasDebt ? 2 : 0,
                          color: hasDebt ? Colors.white : Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: hasDebt
                                ? const BorderSide(
                                    color: Colors.redAccent,
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: hasDebt
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                color: hasDebt ? Colors.red : Colors.blue,
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  customer.phone.isNotEmpty
                                      ? customer.phone
                                      : "Chưa có SĐT",
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (hasDebt)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      "Nợ: ${_currencyFormat.format(customer.currentDebt)} đ",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () async {
                              // 👇 THAY ĐỔI QUAN TRỌNG: Chuyển sang màn hình Lịch sử (Chi tiết)
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderHistoryScreen(
                                    customerId: customer.id,
                                    customerName: customer.name,
                                  ),
                                ),
                              );
                              // Khi quay lại thì reload danh sách để cập nhật số nợ mới
                              _fetchCustomers();
                            },
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
