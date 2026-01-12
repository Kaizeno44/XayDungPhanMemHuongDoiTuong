import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/config/api_config.dart';
import '../providers/auth_provider.dart';

class StockImportHistoryScreen extends StatefulWidget {
  const StockImportHistoryScreen({super.key});

  @override
  State<StockImportHistoryScreen> createState() => _StockImportHistoryScreenState();
}

class _StockImportHistoryScreenState extends State<StockImportHistoryScreen> {
  List<dynamic> _imports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final storeId = authProvider.currentUser?.storeId;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.stockImports}?storeId=$storeId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _imports = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Không thể tải lịch sử');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nhập kho'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : _imports.isEmpty
                  ? const Center(child: Text('Chưa có phiếu nhập nào'))
                  : ListView.builder(
                      itemCount: _imports.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final item = _imports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              item['productName'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Số lượng: ${item['quantity']} ${item['unitName']}'),
                                Text('Giá vốn: ${currencyFormat.format(item['costPrice'])}'),
                                Text('NCC: ${item['supplierName'] ?? "N/A"}'),
                                Text(
                                  'Ngày: ${dateFormat.format(DateTime.parse(item['importDate']))}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Text(
                              currencyFormat.format(item['quantity'] * item['costPrice']),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
