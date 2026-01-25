import 'package:flutter/material.dart';
// Để dùng TextInputFormatter
import 'package:intl/intl.dart';
import 'order_service.dart';

class PayDebtScreen extends StatefulWidget {
  final String customerId;
  final String customerName; // Mới thêm: Để hiển thị tên khách
  final String storeId;
  final double currentDebt;

  const PayDebtScreen({
    super.key,
    required this.customerId,
    required this.customerName, // Required
    required this.storeId,
    required this.currentDebt,
  });

  @override
  State<PayDebtScreen> createState() => _PayDebtScreenState();
}

class _PayDebtScreenState extends State<PayDebtScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _orderService = OrderService();
  final _currencyFormat = NumberFormat("#,##0", "vi_VN");

  bool _isLoading = false;
  String _formattedHelperText = "";

  @override
  void initState() {
    super.initState();
    // Tự động focus vào ô nhập tiền khi mở màn hình
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Hàm điền nhanh số tiền
  void _quickSetAmount(double percent) {
    double amount = widget.currentDebt * percent;
    // Làm tròn về số nguyên
    String text = amount.toStringAsFixed(0);
    _amountController.text = _formatNumber(text); // Format có dấu phẩy luôn
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    ); // Đưa con trỏ về cuối
    _updateHelperText();
  }

  // Hàm xử lý format số khi nhập
  String _formatNumber(String s) {
    if (s.isEmpty) return "";
    s = s.replaceAll(RegExp(r'[^0-9]'), ''); // Xóa ký tự không phải số
    if (s.isEmpty) return "";
    final number = double.parse(s);
    return _currencyFormat.format(number);
  }

  void _onAmountChanged(String value) {
    // Logic format input: User nhập 100000 -> Hiển thị 100,000
    String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) {
      _amountController.text = "";
      _updateHelperText();
      return;
    }

    // Format và gán lại (giữ con trỏ ở cuối)
    String formatted = _formatNumber(cleanValue);
    if (formatted != _amountController.text) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _updateHelperText();
  }

  void _updateHelperText() {
    setState(() {
      String cleanValue = _amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      if (cleanValue.isNotEmpty) {
        double val = double.tryParse(cleanValue) ?? 0;
        // Đọc số thành chữ (Optional - nếu bạn có hàm đọc số)
        // _formattedHelperText = NumberToWords.convert(val);
        _formattedHelperText =
            "Bạn đang nhập: ${_currencyFormat.format(val)} đ";
      } else {
        _formattedHelperText = "";
      }
    });
  }

  Future<void> _submitPayment() async {
    FocusScope.of(context).unfocus();

    // Lấy giá trị thực từ chuỗi đã format (bỏ dấu chấm/phẩy)
    String cleanValue = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final amount = double.tryParse(cleanValue);

    // 1. Validate
    if (amount == null || amount <= 0) {
      _showSnackBar("Vui lòng nhập số tiền hợp lệ", isError: true);
      return;
    }

    if (amount.round() > widget.currentDebt.round()) {
      _showSnackBar(
        "Số tiền trả không được lớn hơn nợ hiện tại",
        isError: true,
      );
      return;
    }

    // 2. Confirm Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận thanh toán"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Khách hàng: ${widget.customerName}"),
            const SizedBox(height: 8),
            Text(
              "Số tiền: ${_currencyFormat.format(amount)} đ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_noteController.text.isNotEmpty)
              Text(
                "Ghi chú: ${_noteController.text}",
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
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

    // 3. Call API
    setState(() => _isLoading = true);
    try {
      // Giả sử API PayDebt hỗ trợ thêm param note
      final result = await _orderService.payDebt(
        customerId: widget.customerId,
        amount: amount,
        storeId: widget.storeId,
        // note: _noteController.text // Nếu API có hỗ trợ note
      );

      if (mounted) {
        _showSnackBar("✅ Thanh toán thành công!");
        Navigator.pop(context, true); // Pop về và báo success
      }
    } catch (e) {
      if (mounted) _showSnackBar("❌ Lỗi: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán công nợ"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER INFO ---
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- DEBT CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Nợ hiện tại",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
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

            // --- INPUT ---
            const Text(
              "Số tiền thanh toán",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: _onAmountChanged, // Format realtime
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              decoration: InputDecoration(
                hintText: "0",
                suffixText: "VNĐ",
                prefixIcon: const Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.green,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                helperText: _formattedHelperText.isNotEmpty
                    ? _formattedHelperText
                    : null,
                helperStyle: const TextStyle(color: Colors.blue),
              ),
            ),

            const SizedBox(height: 12),

            // --- QUICK ACTIONS ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _quickSetAmount(0.5),
                    child: const Text("Trả 50%"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _quickSetAmount(1.0),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text("Trả hết"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- NOTE INPUT ---
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: "Ghi chú (Tùy chọn)",
                hintText: "VD: Chuyển khoản Vietcombank...",
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- SUBMIT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
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
          ],
        ),
      ),
    );
  }
}
