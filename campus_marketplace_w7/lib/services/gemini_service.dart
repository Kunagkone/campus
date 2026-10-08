import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> generateText(String prompt) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('ไม่พบ API Key กรุณาระบุผ่าน --dart-define=GEMINI_API_KEY=...');
    }

    final url = Uri.parse('$_baseUrl?key=$apiKey');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] as String?;
          if (text != null) return text;
        }
        throw Exception('ไม่พบคำตอบจาก Gemini (ข้อมูลตอบกลับไม่สมบูรณ์)');
      } else {
        throw Exception('เรียกใช้งาน Gemini API ไม่สำเร็จ (สถานะ ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา (Timeout 20s)');
    } catch (e) {
      rethrow;
    }
  }
}