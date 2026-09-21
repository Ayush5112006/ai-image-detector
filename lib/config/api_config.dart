/// Central API configuration for ChitraVision AI.
///
/// Override the backend URL at build time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000
class ApiConfig {
  ApiConfig._();

  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// Backend for the app. Override at build time with:
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:4000
  static final String baseUrl =
      _fromEnv.isNotEmpty ? _fromEnv : 'https://ai-image-detector-ebon.vercel.app';
}