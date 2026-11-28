class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Client/demo APKs against the HTTP staging API set this via
  /// `--dart-define=ALLOW_HTTP_API=true`. Production builds must stay HTTPS.
  static const bool allowHttpApi = bool.fromEnvironment(
    'ALLOW_HTTP_API',
    defaultValue: false,
  );
}
