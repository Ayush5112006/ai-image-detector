import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Sends a verification OTP via the ChitraVision backend.
///
/// The OTP is generated and stored server-side (see `POST /api/auth/send-otp`),
/// so email credentials never live inside the app or get bundled into builds.
class EmailService {
  EmailService._();

  static Future<void> sendOtp({required String toEmail}) async {
    final url = '${ApiConfig.baseUrl}/api/auth/send-otp';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': toEmail}),
    );

    if (response.statusCode != 200) {
      String message = 'Could not send the verification email.';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }
}