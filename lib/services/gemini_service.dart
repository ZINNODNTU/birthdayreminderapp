import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyBr2pe7v3PAcHFWdoKPfIkZCBiM62tS84w'; // Replace with your actual API key
  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  /// Hàm chung gọi API và phân tích kết quả
  static Future<List<String>> _fetchSuggestions(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('candidates') &&
            data['candidates'] is List &&
            data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0] as Map<String, dynamic>;
          if (candidate.containsKey('content')) {
            final content = candidate['content'] as Map<String, dynamic>;
            final parts = content['parts'] as List<dynamic>;
            final text = (parts[0] as Map<String, dynamic>)['text'] as String;

            final suggestions = text
                .split(RegExp(r'\n+|\d+\.\s+|-'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && e.length > 3)
                .take(5)
                .toList();

            if (suggestions.isEmpty) {
              throw Exception('Không có gợi ý hợp lệ.');
            }

            return suggestions;
          }
        }
        throw Exception('Cấu trúc phản hồi không hợp lệ: ${response.body}');
      } else {
        throw Exception('Lỗi API Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi khi gọi Gemini API: $e');
    }
  }

  /// Gợi ý quà tặng
  static Future<List<String>> getGiftSuggestions(String prompt) {
    return _fetchSuggestions(prompt);
  }

  /// Gợi ý câu chúc
  static Future<List<String>> getWishSuggestions(String prompt) {
    return _fetchSuggestions(prompt);
  }
}
