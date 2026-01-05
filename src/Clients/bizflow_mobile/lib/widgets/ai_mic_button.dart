import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../cart_provider.dart';
import '../models.dart'; // 👈 QUAN TRỌNG: Phải có dòng này để hiểu CartItem

class AiMicButton extends StatefulWidget {
  const AiMicButton({super.key});

  @override
  State<AiMicButton> createState() => _AiMicButtonState();
}

class _AiMicButtonState extends State<AiMicButton> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _path;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) return;

      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/voice_order.m4a';

      await _audioRecorder.start(const RecordConfig(), path: _path!);
      
      setState(() => _isRecording = true);
      print("🎙 Đang ghi âm...");
    } catch (e) {
      print("Lỗi ghi âm: $e");
    }
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;

    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    if (path != null) {
      print("⏹ File ghi âm tại: $path");
      await _sendToAiService(path);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendToAiService(String filePath) async {
    try {
      // ⚠️ LƯU Ý IP: 
      // - Máy ảo Android: 10.0.2.2
      // - Máy thật: Dùng IP LAN
      var uri = Uri.parse('http://10.0.2.2:5005/api/ai/analyze-voice'); 
      
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      print("📡 Đang gửi lên AI...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        print("✅ AI Trả về: $decoded");
        
        if (decoded['success'] == true) {
          _processAiResult(decoded['data']);
        }
      } else {
        print("❌ Lỗi Server: ${response.statusCode}");
        _showError("Lỗi Server: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối AI: $e");
      _showError("Lỗi kết nối: $e");
    }
  }

  void _processAiResult(Map<String, dynamic> data) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = data['items'] as List;
    
    int successCount = 0;

    for (var item in items) {
      if (item['product_id'] != null) {
        
        // Parse số an toàn
        final num priceNum = item['price'] ?? 0;
        final num qtyNum = item['quantity'] ?? 1;

        // 👇 Đã có CartItem nhờ import models.dart
        final cartItem = CartItem(
          productId: item['product_id'],
          productName: item['official_name'] ?? item['product_name'],
          unitId: 1, 
          unitName: item['unit'] ?? 'Cái',
          price: priceNum.toDouble(), 
          quantity: qtyNum.toInt(), 
        );

        cart.addToCart(cartItem); 
        successCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successCount > 0 
            ? "🤖 Đã thêm $successCount sản phẩm!" 
            : "🤖 Không tìm thấy sản phẩm."),
          backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _startRecording,
      onLongPressUp: _stopAndSend,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : (_isProcessing ? Colors.grey : Colors.blue[800]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: _isProcessing
            ? const Padding(
                padding: EdgeInsets.all(18.0),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 35,
              ),
      ),
    );
  }
}