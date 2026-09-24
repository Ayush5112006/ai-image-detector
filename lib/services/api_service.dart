import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Error thrown whenever the backend returns a non-2xx status.
/// [code] mirrors the server's `error.code` (HTTP_TIMEOUT / NETWORK_ERROR
/// are client-side synthetic codes).
class ApiException implements Exception {
  final String message;
  final String code;
  const ApiException(this.message, {this.code = 'UNKNOWN'});

  @override
  String toString() => message;
}

/// Thin JSON client for the ChitraVision REST API.
/// Handles JWT storage, auth headers and user caching.
class ApiService {
  ApiService._();

  static const _tokenKey = 'auth_token';
  static const _requestTimeout = Duration(seconds: 20);
  static const _uploadTimeout = Duration(seconds: 120);
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

  /// Probes the backend with the stored token (short timeout) so a stale or
  /// rotated token is caught at startup instead of after the user reaches the
  /// home screen. Only an explicit `401` clears the session; offline or server
  /// hiccups keep the cached session so the app still opens.
  static Future<bool> isSessionValid() async {
    final token = await _loadToken();
    if (token == null) return false;
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 401) {
        await clearSession();
        return false;
      }
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return true;
    }
  }

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
    required String otp,
  }) async {
    final data = await _request(
      'POST',
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password, 'otp': otp},
    );
    await _acceptSession(data);
    return data['user'] as Map<String, dynamic>? ?? {};
  }

  /// Exchanges a Google ID token (from Firebase) for a ChitraVision JWT and
  /// the user profile. Creates the account server-side on first sign-in.
  static Future<Map<String, dynamic>> signInWithGoogle({
    required String idToken,
  }) async {
    final data = await _request('POST', '/api/auth/google', body: {
      'idToken': idToken,
    });
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

  /// Signs out every other device. The backend rotates its token version,
  /// invalidating all older JWTs, and hands back a fresh token for this device.
  static Future<void> logoutOtherDevices() async {
    final data = await _request('POST', '/api/auth/logout-all');
    final token = data['token'] as String?;
    if (token != null) await saveToken(token);
  }

  /// Permanently deletes the signed-in account (and its data) server-side,
  /// then clears the local session.
  static Future<void> deleteAccount() async {
    await _request('DELETE', '/api/auth/me');
    await clearSession();
  }

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

  /// Changes the password for the currently signed-in user.
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _request('POST', '/api/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

  // ── Detections ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDetections() async {
    final data = await _request('GET', '/api/detections');
    return (data['detections'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  /// Uploads media and runs the full backend pipeline:
  /// Node backend → FastAPI → HuggingFace model → MongoDB.
  ///
  /// [client] may be supplied by the caller so the request can be aborted
  /// (via `client.close()`) to support user cancellation.
  static Future<Map<String, dynamic>> analyzeMediaFile({
    required String modelId,
    required String fileName,
    required Uint8List bytes,
    http.Client? client,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/detections/analyze');
    final request = http.MultipartRequest('POST', uri)
      ..fields['modelId'] = modelId
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
    final token = await _loadToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final active = client ?? http.Client();
    try {
      final streamed = await active.send(request).timeout(_uploadTimeout);
      final res = await http.Response.fromStream(streamed).timeout(_uploadTimeout);
      final data = _decodeBody(res);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return _unwrap(data);
      }
      final message = _extractMessage(data);
      if (res.statusCode == 401) await clearSession();
      throw ApiException(message, code: _extractCode(data));
    } on TimeoutException {
      throw const ApiException(
        'The detection service took too long to respond. Please try again.',
        code: 'HTTP_TIMEOUT',
      );
    } on http.ClientException catch (_) {
      throw const ApiException(
        'Cannot reach the server. Check your internet connection.',
        code: 'NETWORK_ERROR',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Cannot reach the server. Check your internet connection.',
        code: 'NETWORK_ERROR',
      );
    } finally {
      if (client == null) active.close();
    }
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
          res = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_requestTimeout);
        case 'PATCH':
          res = await http
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_requestTimeout);
        case 'DELETE':
          res = await http.delete(uri, headers: headers).timeout(_requestTimeout);
        default:
          res = await http.get(uri, headers: headers).timeout(_requestTimeout);
      }
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
        code: 'HTTP_TIMEOUT',
      );
    } on http.ClientException catch (_) {
      throw const ApiException(
        'Cannot reach the server. Check your internet connection.',
        code: 'NETWORK_ERROR',
      );
    } catch (_) {
      throw const ApiException(
        'Cannot reach the server. Check your internet connection.',
        code: 'NETWORK_ERROR',
      );
    }

    final data = _decodeBody(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _unwrap(data);
    }

    final message = _extractMessage(data);
    if (res.statusCode == 401) await clearSession();
    throw ApiException(message, code: _extractCode(data));
  }

  /// Extracts the payload from the standardized `{ success, message, data }`
  /// envelope. Falls back to the raw body for resilience against servers
  /// that already returned an unwrapped payload.
  static Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) return {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }

  static Map<String, dynamic>? _decodeBody(http.Response res) {
    final text = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes);
    if (text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Non-JSON body — fall through to a generic message.
    }
    return null;
  }

  static String _extractMessage(Map<String, dynamic>? data) {
    if (data == null) return 'Something went wrong. Please try again.';
    final msg = data['message']?.toString();
    if (msg != null && msg.isNotEmpty) return msg;
    final err = data['error'];
    if (err is Map && err['message'] != null) {
      return err['message'].toString();
    }
    return 'Something went wrong. Please try again.';
  }

  static String _extractCode(Map<String, dynamic>? data) {
    final err = data?['error'];
    if (err is Map && err['code'] != null) return err['code'].toString();
    return data?['code']?.toString() ?? 'UNKNOWN';
  }
}