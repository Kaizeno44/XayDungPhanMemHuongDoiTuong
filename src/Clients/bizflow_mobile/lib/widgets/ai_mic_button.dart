import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'ai_draft_dialog.dart'; // <--- Import Dialog mới

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

      // Start recording
      await _audioRecorder.start(const RecordConfig(), path: _path!);

      setState(() => _isRecording = true);
      debugPrint("🎙 Đang ghi âm...");
    } catch (e) {
      debugPrint("Lỗi ghi âm: $e");
      _showError("Không thể ghi âm: $e");
    }
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      if (path != null) {
        debugPrint("⏹ File ghi âm tại: $path");
        await _sendToAiService(path);
      }
    } catch (e) {
      _showError("Lỗi khi dừng ghi âm: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendToAiService(String filePath) async {
    try {
      // ⚠️ Cấu hình IP Host
      var uri = Uri.parse('http://10.0.2.2:5005/api/ai/analyze-voice');

      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      debugPrint("📡 Đang gửi lên AI...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Decode UTF8 để không lỗi font tiếng Việt
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("✅ AI Trả về: $decoded");

        if (decoded['success'] == true) {
          // [SỬA ĐỔI QUAN TRỌNG] -> Hiện Dialog thay vì auto add
          _showDraftDialog(decoded['data']);
        } else {
          // Hiện thông báo lỗi logic từ server (VD: Không nghe rõ)
          _showError(decoded['message'] ?? "AI không hiểu yêu cầu.");
        }
      } else {
        debugPrint("❌ Lỗi Server: ${response.statusCode}");
        _showError("Lỗi Server AI (${response.statusCode}). Vui lòng thử lại.");
      }
    } catch (e) {
      debugPrint("❌ Lỗi kết nối AI: $e");
      _showError("Không kết nối được tới AI Service. Kiểm tra mạng/IP.");
    }
  }

  void _showDraftDialog(Map<String, dynamic> data) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc user phải chọn Hủy hoặc Xác nhận
      builder: (context) => AiDraftDialog(data: data),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _startRecording,
      onLongPressUp: _stopAndSend,
      // Thêm onTap để hướng dẫn người dùng nếu họ bấm nhầm (không giữ)
      onTap: () {
        if (!_isProcessing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🎙 Giữ lì nút để nói, thả ra để gửi."),
              duration: Duration(milliseconds: 1000),
            ),
          );
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: _isRecording
              ? Colors.red
              : (_isProcessing ? Colors.blue[900] : Colors.blue[800]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isProcessing
            ? const SpinKitWave(color: Colors.white, size: 30.0)
            : Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 35,
              ),
      ),
    );
  }
}
