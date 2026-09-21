import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import '../config/api_config.dart';
import '../config/email_config.dart';

class EmailService {
  EmailService._();

  static String generateOtp() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  static Future<void> sendOtp({
    required String toEmail,
    required String otp,
  }) async {
    if (kIsWeb) {
      await _sendViaEmailJs(toEmail: toEmail, otp: otp);
    } else {
      await _sendViaSmtp(toEmail: toEmail, otp: otp);
    }
  }

  /// Sends OTP via the ChitraVision backend (Gmail SMTP). Works on web.
  static Future<void> _sendViaEmailJs({
    required String toEmail,
    required String otp,
  }) async {
    final url = '${ApiConfig.baseUrl}/api/auth/send-otp';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': toEmail,
        'otp': otp,
      }),
    );

    debugPrint('Send-OTP response status: ${response.statusCode}');
    debugPrint('Send-OTP response body: "${response.body}"');

    if (response.statusCode != 200) {
      String message = 'Send-OTP error ${response.statusCode}';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Sends OTP via Gmail SMTP (works on Android/iOS/desktop).
  static Future<void> _sendViaSmtp({
    required String toEmail,
    required String otp,
  }) async {
    final smtpServer = gmail(
      EmailConfig.senderEmail,
      EmailConfig.senderAppPassword,
    );

    final message = Message()
      ..from = Address(EmailConfig.senderEmail, 'ChitraVision AI')
      ..recipients.add(toEmail)
      ..subject = 'ChitraVision Verification Code'
      ..text =
          'Your ChitraVision verification code is $otp. '
              'Enter this code in the app to finish creating your account.'
      ..html = '''
      <div style="font-family: Arial, sans-serif; max-width: 420px; margin: 0 auto;">
        <h2 style="color: #007AFF; margin-bottom: 8px;">ChitraVision AI</h2>
        <p style="color: #1F2937;">Your verification code is:</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1F2937; background: #EFF4FB; border-radius: 10px; padding: 14px 20px; display: inline-block;">
          $otp
        </div>
        <p style="color: #6B7280; margin-top: 16px;">
          Enter this code in the app to finish creating your account. This code expires in 5 minutes.
        </p>
        <p style="color: #9CA3AF; font-size: 12px;">If you did not request this code, you can safely ignore this email.</p>
      </div>
      ''';

    await send(message, smtpServer);
  }
}
