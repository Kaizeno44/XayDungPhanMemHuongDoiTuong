import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bizflow_mobile/core/config/api_config.dart'; // Sử dụng config có sẵn nếu có

class AiService {
  // LƯU Ý QUAN TRỌNG:
  // - Nếu chạy máy ảo Android: Dùng 10.0.2.2
  // - Nếu chạy máy thật/iOS: Dùng IP LAN của máy tính (ví dụ 192.168.1.x)
  // - Cổng 5005 là cổng chúng ta map ra ngoài Docker
  static const String _baseUrl = 'http://10.0.2.2:5005/api/ai/analyze-voice'; 

  Future<Map<String, dynamic>?> sendVoiceOrder(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      // Đính kèm file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      print("📡 Đang gửi file âm thanh lên AI Service...");
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        print("✅ AI Trả về: $decoded");
        
        if (decoded['success'] == true) {
          return decoded['data']; // Trả về phần data chứa list items
        }
      } else {
        print("❌ Lỗi Server: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối AI: $e");
    }
    return null;
  }
}