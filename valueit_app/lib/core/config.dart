class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get apiV1 => '$apiBaseUrl/api/v1';

  /// Resolves photo URL from API (`url` field) or legacy local uploads path.
  static String photoUrl({required String filePath, String? url}) {
    if (url != null && url.isNotEmpty) return url;
    return '$apiBaseUrl/uploads/$filePath';
  }
}
