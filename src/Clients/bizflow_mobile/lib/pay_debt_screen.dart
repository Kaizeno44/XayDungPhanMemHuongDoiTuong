import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_service.dart';

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
  final _orderService = OrderService();
  final _currencyFormat = NumberFormat("#,##0", "vi_VN");

  bool _isLoading = false;
  String _formattedInput = "";

  @override
  void initState() {
    super.initState();
    // Tự động focus và format số tiền
    _amountController.addListener(() {
      final text = _amountController.text;
      if (text.isNotEmpty) {
        final number = double.tryParse(text) ?? 0;
        setState(() {
          _formattedInput = "${_currencyFormat.format(number)} VNĐ";
        });
      } else {
        setState(() => _formattedInput = "");
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _fillFullAmount() {
    _amountController.text = widget.currentDebt.toStringAsFixed(0);
  }

  Future<void> _submitPayment() async {
    FocusScope.of(context).unfocus();
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      _showSnackBar("Vui lòng nhập số tiền hợp lệ", isError: true);
      return;
    }

    if (amount.round() > widget.currentDebt.round()) {
      _showSnackBar(
        "Số tiền trả lớn hơn nợ thực tế (${_currencyFormat.format(widget.currentDebt)})",
        isError: true,
      );
      return;
    }

    // Dialog xác nhận đẹp hơn
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Xác nhận thu tiền"),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(text: "Xác nhận thu của khách:\n\n"),
              TextSpan(
                text: "${_currencyFormat.format(amount)} VNĐ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            // Sử dụng màu cam hoặc xanh lá cho hành động "Thu tiền"
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Màu xanh nghĩa là tiền vào
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Đồng ý Thu"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await _orderService.payDebt(
        customerId: widget.customerId,
        amount: amount,
        storeId: widget.storeId,
      );

      if (mounted) {
        _showSnackBar("✅ ${result['message'] ?? 'Đã thanh toán thành công!'}");
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("❌ $e", isError: true);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thu nợ khách hàng"),
        // Tự động dùng Theme màu cam
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Nhập số tiền khách trả",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Ô nhập tiền to rõ
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              // ✅ Đổi màu chữ sang Cam (hoặc Xanh) cho đồng bộ
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "0",
                suffixText: "đ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none, // Bỏ viền cho sạch
                ),
                filled: true,
                fillColor: Colors.grey[50], // Nền rất nhạt
                helperText: _formattedInput.isNotEmpty ? _formattedInput : null,
                helperStyle: const TextStyle(
                  color: Colors.green, // Helper màu xanh để dễ đọc
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút gợi ý điền hết nợ (Chip)
            if (widget.currentDebt > 0)
              ActionChip(
                avatar: const Icon(Icons.input, size: 16, color: Colors.white),
                label: Text(
                  "Thu hết nợ cũ: ${_currencyFormat.format(widget.currentDebt)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor:
                    Colors.orange[300], // Màu cam nhạt hơn nút chính
                onPressed: _fillFullAmount,
                side: BorderSide.none,
                shape: const StadiumBorder(),
              ),

            const Spacer(),

            // Nút Xác nhận
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  // ✅ Đổi sang màu Theme (Cam)
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.orange.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "XÁC NHẬN THANH TOÁN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 20,
            ),
          ],
        ),
      ),
    );
  }
}