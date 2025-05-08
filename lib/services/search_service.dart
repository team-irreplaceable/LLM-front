import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  static const String _baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>> searchNews({
    required String query,
    String? publisher,
  }) async {
    final Map<String, String> queryParams = {
      'query': query,
      if (publisher != null && publisher != '전체') 'publisher': publisher,
    };

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> getKeywordSummary(String keyword) async {
    final uri = Uri.parse('$_baseUrl/keyword-summary').replace(
      queryParameters: {'keyword': keyword},
    );
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get keyword summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
} 