import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// One plug-in module (Notes, Vault, ...) as the app shell sees it.
///
/// From this description alone the shell builds the module's route
/// (`/home/features/<id>`), its dashboard tile and its entry in the '+' picker.
class FeatureModule {
  const FeatureModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.pageBuilder,
    this.pinnedByDefault = false,
    this.routes = const [],
  });

  /// Lowercase URL slug, e.g. `notes`.
  ///
  /// Also the key in saved dashboards, so never rename it.
  final String id;

  final String title;
  final IconData icon;

  /// Builds the module's main page. Gets the [GoRouterState] so a page can
  /// read path or query parameters.
  final GoRouterWidgetBuilder pageBuilder;

  /// Whether a dashboard shows this module before the user customises it.
  final bool pinnedByDefault;

  /// Optional nested routes, relative to the module's own path
  /// (e.g. `':noteId'` for `/home/features/notes/<noteId>`).
  final List<RouteBase> routes;
}
