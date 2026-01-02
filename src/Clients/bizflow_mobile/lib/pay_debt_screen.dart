import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_service.dart'; // Nhớ import file service

class PayDebtScreen extends StatefulWidget {
  final String customerId;
  final String storeId;
  final double currentDebt;

  const PayDebtScreen({
    super.key,
    required this.customerId,
    required this.storeId,
    required this.currentDebt,
  });

  @override
  State<PayDebtScreen> createState() => _PayDebtScreenState();
}

class _PayDebtScreenState extends State<PayDebtScreen> {
  final _amountController = TextEditingController();
  final _orderService = OrderService(); // Khởi tạo Service
  final _currencyFormat = NumberFormat("#,##0", "vi_VN");

  bool _isLoading = false;
  String _formattedInput = ""; // Biến để hiển thị số tiền format khi gõ

  @override
  void initState() {
    super.initState();
    // Lắng nghe thay đổi text field để cập nhật hiển thị format
    _amountController.addListener(() {
      final text = _amountController.text;
      if (text.isNotEmpty) {
        final number = double.tryParse(text) ?? 0;
        setState(() {
          _formattedInput = "${_currencyFormat.format(number)} VNĐ";
        });
      } else {
        setState(() {
          _formattedInput = "";
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Hàm điền nhanh toàn bộ số nợ
  void _fillFullAmount() {
    // Chỉ lấy phần nguyên để tránh lỗi thập phân khi hiển thị lên TextField
    _amountController.text = widget.currentDebt.toStringAsFixed(0);
  }

  Future<void> _submitPayment() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    final amount = double.tryParse(_amountController.text);

    // 1. Validate đầu vào
    if (amount == null || amount <= 0) {
      _showSnackBar("Vui lòng nhập số tiền hợp lệ", isError: true);
      return;
    }

    // Sử dụng làm tròn (round) để tránh lỗi so sánh số thực (floating point precision)
    // do VNĐ không có phần thập phân nhưng API có thể trả về số thực.
    if (amount.round() > widget.currentDebt.round()) {
      _showSnackBar(
        "Số tiền trả không được lớn hơn nợ hiện tại",
        isError: true,
      );
      return;
    }

    // 2. Hỏi xác nhận trước khi gửi (UX tốt hơn)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận thanh toán"),
        content: Text(
          "Bạn có chắc muốn thanh toán số tiền ${_currencyFormat.format(amount)} VNĐ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Đồng ý", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. Gọi API
    setState(() => _isLoading = true);

    try {
      final result = await _orderService.payDebt(
        customerId: widget.customerId,
        amount: amount,
        storeId: widget.storeId,
      );

      if (mounted) {
        _showSnackBar("✅ ${result['message'] ?? 'Thanh toán thành công!'}");
        Navigator.pop(context, true); // Trả về true để refresh list
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("❌ $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán nợ"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Thêm Scroll để tránh bị che bởi bàn phím
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card hiển thị nợ hiện tại
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    "Nợ hiện tại",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_currencyFormat.format(widget.currentDebt)} đ",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Input nhập tiền
            const Text(
              "Nhập số tiền trả:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: "0",
                suffixText: "VNĐ",
                border: const OutlineInputBorder(),
                // Hiển thị số tiền format ngay dưới ô input
                helperText: _formattedInput.isNotEmpty ? _formattedInput : null,
                helperStyle: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Nút Quick Action: Trả hết
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _fillFullAmount,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text("Điền toàn bộ số nợ"),
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
            ),

            const SizedBox(height: 30),

            // Nút Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "XÁC NHẬN THANH TOÁN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
