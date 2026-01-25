import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_service.dart';

class PayDebtScreen extends StatefulWidget {
  final String customerId;
  final String storeId;
  final double currentDebt; // Giữ lại để validate không cho nhập quá số nợ

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
    // Tự động focus vào ô nhập tiền
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

    // Xác nhận trước khi trừ tiền
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận thu tiền"),
        content: Text("Thu của khách: ${_currencyFormat.format(amount)} VNĐ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("Đồng ý", style: TextStyle(color: Colors.white)),
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
        _showSnackBar("✅ ${result['message'] ?? 'Đã thanh toán!'}");
        Navigator.pop(
          context,
          true,
        ); // Trả về true để màn hình trước reload lại
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
        title: const Text("Nhập số tiền thu"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Ô nhập tiền to rõ
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "0",
                suffixText: "đ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                helperText: _formattedInput.isNotEmpty ? _formattedInput : null,
                helperStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nút gợi ý điền hết nợ
            if (widget.currentDebt > 0)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _fillFullAmount,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    "Thu hết nợ cũ (${_currencyFormat.format(widget.currentDebt)})",
                  ),
                ),
              ),

            const Spacer(),

            // Nút Xác nhận
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 20,
            ),
          ],
        ),
      ),
    );
  }
}
