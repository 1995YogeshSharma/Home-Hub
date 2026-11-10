/// Every URL in the app, so no screen hard-codes a path string.
///
/// Navigate with these, e.g. `context.go(AppRoutes.feature('notes'))`.
abstract final class AppRoutes {
  static const root = '/';
  static const home = '/home';
  static const status = '/home/status';

  /// The page of the feature module with [featureId], e.g. `/home/features/notes`.
  static String feature(String featureId) => '/home/features/$featureId';
}
