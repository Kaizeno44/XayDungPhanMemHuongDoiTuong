import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// [QUAN TRỌNG] Import màn hình Chi tiết (OrderHistoryScreen)
import 'package:bizflow_mobile/order_history_screen.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  List<dynamic> _debtors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Gọi API ngay khi màn hình mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDebtors();
    });
  }

  // --- HÀM GỌI API LẤY KHÁCH NỢ ---
  Future<void> _fetchDebtors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // [FIX LỖI KHÔNG HIỆN DỮ LIỆU]
      // Bỏ tham số ?storeId=... để lấy tất cả khách hàng (giống logic bên checkout)
      // Điều này giúp tránh lỗi nếu storeId của User và Customer bị lệch nhau
      final url = Uri.parse("http://10.0.2.2:5103/api/Customers");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allCustomers = jsonDecode(response.body);

        // Lọc danh sách: Chỉ lấy khách có nợ > 0
        final debtors = allCustomers.where((c) {
          final debt = (c['currentDebt'] ?? 0).toDouble();
          return debt > 0; // Chỉ lấy người có nợ
        }).toList();

        // Sắp xếp: Người nợ nhiều nhất lên đầu
        debtors.sort(
          (a, b) => (b['currentDebt'] ?? 0).compareTo(a['currentDebt'] ?? 0),
        );

        setState(() {
          _debtors = debtors;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Lỗi tải dữ liệu: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi kết nối: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ Nợ Khách Hàng'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDebtors, // Nút làm mới danh sách
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchDebtors,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            )
          : _debtors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green.shade200,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Tuyệt vời! Không có khách nào nợ tiền.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _debtors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = _debtors[index];
                final currentDebt = (customer['currentDebt'] ?? 0).toDouble();

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      radius: 24,
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.red.shade700,
                      ),
                    ),
                    title: Text(
                      customer['name'] ?? 'Khách lẻ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      customer['phone'] ?? '---',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(currentDebt),
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem chi tiết ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () async {
                      // [QUAN TRỌNG] Chuyển sang màn hình CHI TIẾT (Lịch sử + Trả nợ)
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderHistoryScreen(
                            customerId: customer['id'].toString(),
                            customerName: customer['name'] ?? 'Khách hàng',
                          ),
                        ),
                      );

                      // Quay lại thì reload danh sách (phòng trường hợp đã trả hết nợ)
                      _fetchDebtors();
                    },
                  ),
                );
              },
            ),
    );
  }
}
