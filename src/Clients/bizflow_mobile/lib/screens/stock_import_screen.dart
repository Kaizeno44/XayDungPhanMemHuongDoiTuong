// Thay thế nội dung file: lib/screens/stock_import_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models.dart';
import '../core/config/api_config.dart';
import '../providers/auth_provider.dart';

class StockImportScreen extends StatefulWidget {
  final Product product;

  const StockImportScreen({super.key, required this.product});

  @override
  State<StockImportScreen> createState() => _StockImportScreenState();
}

class _StockImportScreenState extends State<StockImportScreen> {
  final _formKey = GlobalKey<FormState>();
  ProductUnit? _selectedUnit;
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Logic tìm đơn vị cơ sở tốt rồi, giữ nguyên
    if (widget.product.productUnits.isNotEmpty) {
      _selectedUnit = widget.product.productUnits.firstWhere(
        (u) => u.isBaseUnit,
        orElse: () => widget.product.productUnits.first,
      );
    }
  }

  Future<void> _submitImport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đơn vị tính')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final storeId = authProvider.currentUser?.storeId;

    if (storeId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy Store ID')),
      );
      return;
    }

    // Xử lý parse double an toàn (thay dấu phẩy thành chấm nếu user lỡ nhập sai)
    final quantity =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
    final costPrice =
        double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0;

    final body = {
      'productId': widget.product.id,
      'unitId': _selectedUnit!.id,
      'quantity': quantity,
      'costPrice': costPrice,
      'supplierName': _supplierController.text,
      'note': _noteController.text,
      'storeId': storeId.toString(), // Đảm bảo chuyển sang String
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.stockImports),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nhập kho thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Server trả về: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thêm kiểm tra nếu sản phẩm chưa có đơn vị nào
    if (widget.product.productUnits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(
          child: Text("Sản phẩm này chưa cấu hình đơn vị tính"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo phiếu nhập kho'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sản phẩm: ${widget.product.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<ProductUnit>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị nhập',
                  border: OutlineInputBorder(),
                ),
                items: widget.product.productUnits.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.unitName),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedUnit = val),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng nhập',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Vui lòng nhập số lượng';
                  if (double.tryParse(val.replaceAll(',', '.')) == null)
                    return 'Số lượng không hợp lệ';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _costPriceController,
                decoration: const InputDecoration(
                  labelText: 'Giá vốn (đơn giá)',
                  border: OutlineInputBorder(),
                  suffixText: 'VNĐ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Vui lòng nhập giá vốn';
                  if (double.tryParse(val.replaceAll(',', '.')) == null)
                    return 'Giá tiền không hợp lệ';
                  return null;
                },
              ),

              // ... Các trường khác giữ nguyên ...
              const SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Nhà cung cấp',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'XÁC NHẬN NHẬP KHO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
