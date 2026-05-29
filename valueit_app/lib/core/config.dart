class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get apiV1 => '$apiBaseUrl/api/v1';
  static String uploadUrl(String path) => '$apiBaseUrl/uploads/$path';
}
