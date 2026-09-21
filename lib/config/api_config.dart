import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central API configuration for ChitraVision AI.
///
/// The backend URL is resolved in this priority order:
///   1. --dart-define=API_BASE_URL=...  (build-time override)
///   2. API_BASE_URL in the app `.env` file
///   3. the production default
class ApiConfig {
  ApiConfig._();

  static const String _fromDartDefine = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromDartDefine.isNotEmpty) return _fromDartDefine;
    final fromEnvFile = dotenv.maybeGet('API_BASE_URL', fallback: '');
    if (fromEnvFile != null && fromEnvFile.isNotEmpty) return fromEnvFile;
    return 'https://ai-image-detector-ebon.vercel.app';
  }
}