import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final ApiService _api = ApiService.instance;

  Future<Map?> register(Map profile, String email, String password) async {
    final body = {
      ...profile,
      'email': email,
      'password': password,
    };

    final res = await _api.post('/auth/register', body);
    if (res.statusCode == 201) {
      final j = jsonDecode(res.body);
      final token = j['data']['token'];
      await _api.saveToken(token);
      return j['data'];
    }

    final msg = _extractError(
        res.body, 'Registration failed. Email might already exist.');
    throw Exception(msg);
  }

  /// `identifier` may be either email or nickname per backend API.
  Future<Map?> login(String identifier, String password) async {
    final res = await _api
        .post('/auth/login', {'identifier': identifier, 'password': password});
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      final token = j['data']['token'];
      await _api.saveToken(token);
      return j['data'];
    }

    final msg = _extractError(res.body, 'Invalid identifier or password.');
    throw Exception(msg);
  }

  String _extractError(String body, String fallback) {
    try {
      final j = jsonDecode(body);
      final errors = j['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstList = errors.values.first;
        if (firstList is List && firstList.isNotEmpty) {
          return firstList.first.toString();
        }
      }
      return j['message'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> logout() async {
    await _api.post('/auth/logout', {});
    await _api.clearToken();
  }

  Future<Map?> getProfile() async {
    final res = await _api.get('/auth/me');
    if (res.statusCode == 200) {
      return _extractUserMap(jsonDecode(res.body));
    }
    return null;
  }

  Future<Map?> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.put('/auth/profile', data);
    if (res.statusCode == 200) {
      return _extractUserMap(jsonDecode(res.body));
    }
    debugPrint('updateProfile failed: ${res.statusCode} — ${res.body}');
    return null;
  }

  Map? _extractUserMap(dynamic decoded) {
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is Map) {
        final user = data['user'];
        if (user is Map) return user;
        if (data['profile'] is Map) return data['profile'] as Map;
      }
      if (decoded['user'] is Map) return decoded['user'] as Map;
      if (decoded['profile'] is Map) return decoded['profile'] as Map;
    }
    return null;
  }
}
