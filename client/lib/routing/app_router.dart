import 'package:go_router/go_router.dart';

import '../app/app_dependencies.dart';
import '../core/ui/not_found_page.dart';
import '../dashboard/dashboard_page.dart';
import '../server_status/server_status_page.dart';
import 'app_routes.dart';

/// Builds the app's route tree.
///
/// A factory rather than a global, so every test gets a fresh router.
GoRouter createRouter({
  required AppDependencies deps,
  String initialLocation = AppRoutes.home,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
    routes: [
      // `/` has no page of its own yet; onboarding will take it over later.
      GoRoute(path: AppRoutes.root, redirect: (_, _) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => DashboardPage(
          session: deps.session.requireSession,
          features: deps.features,
          repository: deps.dashboardRepository,
        ),
        // Child paths are relative: 'status' means /home/status.
        routes: [
          GoRoute(
            path: 'status',
            builder: (context, state) => ServerStatusPage(api: deps.api),
          ),
          // One route per module: unknown ids fall through to errorBuilder,
          // and each module can bring its own nested routes.
          for (final module in deps.features.all)
            GoRoute(
              path: 'features/${module.id}',
              builder: module.pageBuilder,
              routes: module.routes,
            ),
        ],
      ),
    ],
  );
}
