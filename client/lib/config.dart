/// Build-time configuration, overridable with `--dart-define=KEY=value`.
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://server.home.hub:8000',
  );
}
