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
  final TextEditingController _searchController = TextEditingController();

  // Dữ liệu gốc từ API
  List<Customer> _allCustomers = [];
  // Dữ liệu đã lọc để hiển thị (Tối ưu hiệu năng)
  List<Customer> _filteredCustomers = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Gọi API ngay sau khi màn hình được dựng xong
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Hàm lấy dữ liệu từ API
  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userState = ref.read(authNotifierProvider);
    final storeId = userState.currentUser?.storeId;

    if (storeId == null || storeId.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Không tìm thấy thông tin cửa hàng.";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final customers = await _orderService.getCustomers(storeId: storeId);
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _isLoading = false;
          // Sau khi có dữ liệu mới, chạy bộ lọc ngay lập tức
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi kết nối: $e";
          _isLoading = false;
        });
      }
    }
  }

  /// Logic lọc và sắp xếp tách biệt khỏi hàm build
  void _applyFilter() {
    final query = _searchController.text.toLowerCase();

    final temp = _allCustomers.where((c) {
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    // Sắp xếp: Ai nợ nhiều nhất lên đầu
    temp.sort((a, b) => b.currentDebt.compareTo(a.currentDebt));

    setState(() {
      _filteredCustomers = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    // build giờ đây rất nhẹ, chỉ render UI từ _filteredCustomers có sẵn
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sổ Nợ Khách Hàng"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[800], // Thêm màu cho đẹp hơn
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Làm mới",
            onPressed: _fetchCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH SECTION ---
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[800], // Đồng bộ màu AppBar
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm tên hoặc số điện thoại...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // Thêm nút Clear (X) tiện lợi
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter(); // Reset list
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) => _applyFilter(),
            ),
          ),

          // --- LIST SECTION ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _filteredCustomers.isEmpty
                        ? _buildEmptyWidget()
                        : RefreshIndicator(
                            onRefresh: _fetchCustomers,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredCustomers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _buildCustomerCard(_filteredCustomers[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final hasDebt = customer.currentDebt > 0;

    return Card(
      elevation: hasDebt ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasDebt
            ? BorderSide(color: Colors.red.shade200, width: 1)
            : BorderSide.none,
      ),
      color: Colors.white,
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
          // Reload lại danh sách sau khi quay lại (để cập nhật số nợ mới)
          _fetchCustomers();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasDebt ? Colors.red.shade50 : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasDebt ? Icons.history_edu : Icons.check_circle_outline,
                  color: hasDebt ? Colors.red : Colors.green,
                  size: 26,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone.isNotEmpty ? customer.phone : "---",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
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
                      "ĐANG NỢ",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_currencyFormat.format(customer.currentDebt)} đ",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
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

  Widget _buildEmptyWidget() {
    // Nếu đang tìm kiếm mà không thấy
    if (_searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Không tìm thấy \"${_searchController.text}\"",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    // Nếu danh sách rỗng hoàn toàn
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Chưa có khách hàng nào",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchCustomers,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}