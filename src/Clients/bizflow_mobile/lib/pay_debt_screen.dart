import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'order_service.dart'; // Đảm bảo đường dẫn đúng

class PayDebtScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String storeId;
  final double currentDebt;

  const PayDebtScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.storeId,
    required this.currentDebt,
  });

  @override
  State<PayDebtScreen> createState() => _PayDebtScreenState();
}

class _PayDebtScreenState extends State<PayDebtScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(); // ✅ Đã thêm controller này
  final _orderService = OrderService();
  final _currencyFormat = NumberFormat("#,##0", "vi_VN");

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose(); // Giờ đây an toàn để dispose
    super.dispose();
  }

  /// Hàm điền toàn bộ số nợ vào ô nhập
  void _fillFullAmount() {
    // Format số nợ hiện tại thành chuỗi có dấu phân cách (ví dụ: 1,000,000)
    final formattedDebt = _currencyFormat.format(widget.currentDebt);
    _amountController.text = formattedDebt;
    // Di chuyển con trỏ về cuối dòng
    _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length));
  }

  /// Hàm parse số từ chuỗi đã format (1,000,000 -> 1000000.0)
  double _parseCurrency(String text) {
    if (text.isEmpty) return 0;
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  Future<void> _submitPayment() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    final amountText = _amountController.text;
    final amount = _parseCurrency(amountText);
    final note = _noteController.text.trim();

    // 1. Validate Số tiền
    if (amount <= 0) {
      setState(() => _errorText = "Vui lòng nhập số tiền lớn hơn 0");
      return;
    }

    // 2. Validate Trả thừa
    // Cho phép sai số nhỏ (epsilon) để tránh lỗi số học floating point
    if (amount > widget.currentDebt + 100) { 
      setState(() => _errorText = "Số tiền trả vượt quá nợ hiện tại (${_currencyFormat.format(widget.currentDebt)})");
      return;
    }

    setState(() => _errorText = null); // Xóa lỗi cũ

    // 3. Dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.monetization_on, color: Colors.green),
            SizedBox(width: 8),
            Text("Xác nhận thu tiền"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bạn có chắc chắn muốn thu số tiền:"),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "${_currencyFormat.format(amount)} đ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.green,
                ),
              ),
            ),
            if (note.isNotEmpty) ...[
              const Divider(height: 20),
              Text("Ghi chú: $note", style: const TextStyle(fontStyle: FontStyle.italic)),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Đồng ý Thu"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 4. Gọi API
    setState(() => _isLoading = true);
    try {
      final result = await _orderService.payDebt(
        customerId: widget.customerId,
        amount: amount,
        storeId: widget.storeId,
        // note: note, // Uncomment nếu API của bạn hỗ trợ biến 'note'
      );

      if (mounted) {
        _showSnackBar("✅ ${result['message'] ?? 'Thu nợ thành công!'}");
        Navigator.pop(context, true); // Trả về true để màn hình trước refresh lại
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
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Chạm ra ngoài ẩn phím
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Thu nợ khách hàng"),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CARD: THÔNG TIN KHÁCH VÀ NỢ
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(widget.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 20),
                      const Text("Nợ hiện tại", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text(
                        "${_currencyFormat.format(widget.currentDebt)} đ",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // INPUT: SỐ TIỀN
              const Text("Nhập số tiền khách trả:", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(), // Formatter tùy chỉnh ở dưới
                ],
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "0",
                  suffixText: "đ",
                  errorText: _errorText, // Hiển thị lỗi nếu có
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                onChanged: (_) => setState(() => _errorText = null), // Xóa lỗi khi nhập lại
              ),

              // CHIP: TRẢ HẾT
              if (widget.currentDebt > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: ActionChip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                      label: const Text("Thu tất cả nợ cũ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.orange[400],
                      onPressed: _fillFullAmount,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // INPUT: GHI CHÚ
              const Text("Ghi chú (tùy chọn):", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: "Ví dụ: Khách trả tiền mặt...",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),

              const SizedBox(height: 40),

              // BUTTON: XÁC NHẬN
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700], // Màu xanh cho hành động 'Thu tiền'
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("XÁC NHẬN THU TIỀN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HELPER CLASS: FORMAT TIỀN KHI GÕ ---
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###", "vi_VN");

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Xóa tất cả ký tự không phải số
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Parse sang số
    double value = double.tryParse(cleanText) ?? 0;

    // Format lại
    String newText = _formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}