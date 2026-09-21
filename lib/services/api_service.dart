import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Error thrown whenever the backend returns a non-2xx status.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Thin JSON client for the ChitraVision REST API.
/// Handles JWT storage, auth headers and user caching.
class ApiService {
  ApiService._();

  static const _tokenKey = 'auth_token';
  static String? _token;
  static Map<String, dynamic>? _cachedUser;

  // ── Session ──────────────────────────────────────────────────────────────

  static Future<String?> _loadToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearSession() async {
    _token = null;
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Returns `true` when a (possibly stale) JWT is stored locally.
  static Future<bool> isLoggedIn() async => (await _loadToken()) != null;

  static Future<Map<String, dynamic>> me() async {
    final data = await _request('GET', '/api/auth/me');
    final user = data['user'] as Map<String, dynamic>? ?? {};
    _cacheUser(user);
    return user;
  }

  static Map<String, dynamic>? get cachedUser => _cachedUser;

  static void _cacheUser(Map<String, dynamic> user) => _cachedUser = user;

  // ── Auth ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    await _acceptSession(data);
    return data['user'] as Map<String, dynamic>? ?? {};
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    await _acceptSession(data);
    return data['user'] as Map<String, dynamic>? ?? {};
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> fields,
  ) async {
    final data = await _request('PATCH', '/api/auth/me', body: fields);
    final user = data['user'] as Map<String, dynamic>? ?? {};
    _cacheUser(user);
    return user;
  }

  static Future<void> _acceptSession(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    if (token != null) await saveToken(token);
    final user = data['user'] as Map<String, dynamic>?;
    if (user != null) _cacheUser(user);
  }

  /// Requests a password-reset code by email.
  static Future<void> forgotPassword(String email) =>
      _request('POST', '/api/auth/forgot-password', body: {'email': email});

  /// Verifies the reset code and sets a new password.
  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      _request('POST', '/api/auth/reset-password', body: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });

  // ── Detections ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDetections() async {
    final data = await _request('GET', '/api/detections');
    return (data['detections'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createDetection({
    required String modelId,
    required String modelName,
    required String category,
    required String fileName,
    required String verdict,
    required double confidence,
    required String resultLabel,
  }) async {
    final data = await _request(
      'POST',
      '/api/detections',
      body: {
        'modelId': modelId,
        'modelName': modelName,
        'category': category,
        'fileName': fileName,
        'verdict': verdict,
        'confidence': confidence,
        'resultLabel': resultLabel,
      },
    );
    return data['detection'] as Map<String, dynamic>? ?? {};
  }

  static Future<void> deleteDetection(String id) =>
      _request('DELETE', '/api/detections/$id');

  // ── Stats & Premium ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> stats() async {
    final data = await _request('GET', '/api/user/stats');
    return data['stats'] as Map<String, dynamic>? ?? {};
  }

  static Future<Map<String, dynamic>> premiumStatus() async {
    final data = await _request('GET', '/api/user/premium');
    return data['premium'] as Map<String, dynamic>? ?? {};
  }

  static Future<Map<String, dynamic>> activatePremium() async {
    final data = await _request('POST', '/api/user/premium/activate');
    return data['premium'] as Map<String, dynamic>? ?? {};
  }

  // ── Low-level request helper ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await _loadToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';

    late http.Response res;
    try {
      switch (method) {
        case 'POST':
          res = await http.post(uri,
              headers: headers, body: jsonEncode(body ?? {}));
        case 'PATCH':
          res = await http.patch(uri,
              headers: headers, body: jsonEncode(body ?? {}));
        case 'DELETE':
          res = await http.delete(uri, headers: headers);
        default:
          res = await http.get(uri, headers: headers);
      }
    } catch (_) {
      throw const ApiException(
        'Cannot reach the server. Make sure the backend is running.',
      );
    }

    Map<String, dynamic>? data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data ?? {};
    }

    final message = data?['message']?.toString() ??
        'Request failed (HTTP ${res.statusCode})';
    if (res.statusCode == 401) await clearSession();
    throw ApiException(message);
  }
}