import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  String? errorMessage; // Biến lưu thông báo lỗi nếu có

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  // Hàm lấy dữ liệu từ API
  Future<void> fetchHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // QUAN TRỌNG: Đã cập nhật cổng 5103 chuẩn cho OrderAPI
    final url =
        "http://10.0.2.2:5103/api/Customers/${widget.customerId}/history";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orders = data['orders'];
          currentDebt = (data['currentDebt'] as num)
              .toDouble(); // Ép kiểu an toàn
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
        errorMessage =
            "Không thể kết nối đến Server.\nVui lòng kiểm tra lại Backend.";
        print("Lỗi chi tiết: $e");
      });
    }
  }

  // Hàm chọn màu sắc dựa trên trạng thái đơn hàng
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green; // Đã xác nhận -> Xanh lá
      case 'Pending':
        return Colors.orange; // Đang chờ -> Cam
      case 'Cancelled':
        return Colors.red; // Đã hủy -> Đỏ
      case 'Completed':
        return Colors.blue; // Hoàn thành -> Xanh dương
      default:
        return Colors.grey;
    }
  }

  // Hàm dịch trạng thái sang tiếng Việt (nếu cần)
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
        title: const Text("Lịch sử đơn hàng"),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // === PHẦN 1: TỔNG NỢ ===
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border(bottom: BorderSide(color: Colors.red.shade100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "TỔNG DƯ NỢ HIỆN TẠI",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currencyFormat.format(currentDebt),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // === PHẦN 2: DANH SÁCH ĐƠN HÀNG ===
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 10),
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: fetchHistory,
                          child: const Text("Thử lại"),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchHistory, // Vuốt xuống để tải lại
                    child: orders.isEmpty
                        ? ListView(
                            // Dùng ListView để có thể vuốt refresh dù trống
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Chưa có đơn hàng nào",
                                      style: TextStyle(color: Colors.grey),
                                    ),
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
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Dòng 1: Mã đơn và Trạng thái
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.receipt_long,
                                                color: Colors.blue[800],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                order['orderCode'] ?? "CODE",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: statusColor.withOpacity(
                                                  0.5,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              _translateStatus(order['status']),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      // Dòng 2: Chi tiết ngày và tiền
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Ngày đặt: ${dateFormat.format(DateTime.parse(order['orderDate']))}",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "TT: ${order['paymentMethod'] == 'Debt' ? 'Ghi nợ' : 'Tiền mặt'}",
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            currencyFormat.format(
                                              order['totalAmount'],
                                            ),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[900],
                                            ),
                                          ),
                                        ],
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
