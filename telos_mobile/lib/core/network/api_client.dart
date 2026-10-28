import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  static final http.Client _client = http.Client();

  static Map<String, String> _getHeaders() {
    final token = StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}: ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'offline': true};
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}: ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'offline': true};
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client.put(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}: ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'offline': true};
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final response = await _client.patch(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}: ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'offline': true};
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}: ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'offline': true};
    }
  }
}
