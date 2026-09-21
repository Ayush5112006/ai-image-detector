/// Central API configuration for ChitraVision AI.
///
/// Override the backend URL at build time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000
class ApiConfig {
  ApiConfig._();

  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static final String baseUrl =
      _fromEnv.isNotEmpty ? _fromEnv : 'http://localhost:4000';
}