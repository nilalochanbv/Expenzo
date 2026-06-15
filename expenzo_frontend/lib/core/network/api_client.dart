import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../database/hive_database.dart';

class ApiClient {
  static String get defaultBaseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.19.90.176:8081/api';
      }
    } catch (_) {}
    return 'http://localhost:8081/api';
  }

  static String get baseUrl {
    final savedUrl = HiveDatabase.settingsBox.get('serverUrl') as String?;
    if (savedUrl != null && savedUrl.isNotEmpty) {
      return savedUrl;
    }
    return defaultBaseUrl;
  }

  static String? get _token {
    return HiveDatabase.settingsBox.get('token') as String?;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final t = _token;
    if (t != null) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  static Future<http.Response> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      );
      return response;
    } on SocketException {
      throw Exception('No Internet connection');
    }
  }

  static Future<http.Response> post(String path, dynamic body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return response;
    } on SocketException {
      throw Exception('No Internet connection');
    }
  }

  static Future<http.Response> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      );
      return response;
    } on SocketException {
      throw Exception('No Internet connection');
    }
  }
}
