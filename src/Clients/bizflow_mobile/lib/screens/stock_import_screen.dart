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
    _selectedUnit = widget.product.productUnits.firstWhere(
      (u) => u.isBaseUnit,
      orElse: () => widget.product.productUnits.first,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPriceController.dispose();
    _supplierController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitImport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final storeId = authProvider.currentUser?.storeId;

    final body = {
      'productId': widget.product.id,
      'unitId': _selectedUnit!.id,
      'quantity': double.parse(_quantityController.text),
      'costPrice': double.parse(_costPriceController.text),
      'supplierName': _supplierController.text,
      'note': _noteController.text,
      'storeId': storeId,
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
            const SnackBar(content: Text('Nhập kho thành công!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Lỗi: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<ProductUnit>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: 'Đơn vị nhập'),
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
                decoration: const InputDecoration(labelText: 'Số lượng nhập', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập số lượng' : null,
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _costPriceController,
                decoration: const InputDecoration(labelText: 'Giá vốn (Giá nhập)', border: OutlineInputBorder(), suffixText: 'đ'),
                keyboardType: TextInputType.number,
                validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập giá vốn' : null,
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(labelText: 'Nhà cung cấp', border: OutlineInputBorder()),
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitImport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('XÁC NHẬN NHẬP KHO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
