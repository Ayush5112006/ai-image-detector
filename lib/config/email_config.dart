import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailConfig {
  EmailConfig._();

  static String get senderEmail =>
      dotenv.maybeGet('SENDER_EMAIL', fallback: '') ?? '';

  static String get senderAppPassword =>
      dotenv.maybeGet('SENDER_APP_PASSWORD', fallback: '') ?? '';

  // EmailJS credentials (used on web)
  static String get emailJsServiceId =>
      dotenv.maybeGet('EMAILJS_SERVICE_ID', fallback: '') ?? '';

  static String get emailJsTemplateId =>
      dotenv.maybeGet('EMAILJS_TEMPLATE_ID', fallback: '') ?? '';

  static String get emailJsPublicKey =>
      dotenv.maybeGet('EMAILJS_PUBLIC_KEY', fallback: '') ?? '';
}
