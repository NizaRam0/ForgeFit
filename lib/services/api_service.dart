import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  static const String baseUrlAndroid = 'https://forgefit-backend-main-wwdvkb.laravel.cloud/api';
  static const String baseUrliOS = 'https://forgefit-backend-main-wwdvkb.laravel.cloud/api';

  String? _cachedToken;

  String get baseUrl {
    if (Platform.isAndroid) return baseUrlAndroid;
    if (Platform.isIOS || Platform.isMacOS) return baseUrliOS;
    return baseUrlAndroid;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('forgefit_token');
  }

  Future<String?> getToken() async {
    return _token();
  }

  Future<String?> _token() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('forgefit_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final h = await _headers();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: h)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401) await _handleUnauthorized();
      return res;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 408);
    }
  }

  Future<http.Response> post(String path, Map body,
      {int timeoutSeconds = 10}) async {
    final h = await _headers();
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body))
          .timeout(Duration(seconds: timeoutSeconds));
      if (res.statusCode == 401) await _handleUnauthorized();
      return res;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 408);
    }
  }

  Future<http.Response> put(String path, Map body) async {
    final h = await _headers();
    try {
      final res = await http
          .put(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401) await _handleUnauthorized();
      return res;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 408);
    }
  }

  Future<http.Response> delete(String path) async {
    final h = await _headers();
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl$path'), headers: h)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401) await _handleUnauthorized();
      return res;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 408);
    }
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('forgefit_token', token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('forgefit_token');
  }

  Future<void> _handleUnauthorized() async {
    await clearToken();
    // Optionally: navigate to onboarding screen. UI code should listen for token clear.
  }
}
