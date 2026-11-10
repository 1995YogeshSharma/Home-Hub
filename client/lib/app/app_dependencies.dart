import '../api/api_client.dart';
import '../core/session/session_controller.dart';
import '../dashboard/dashboard_repository.dart';
import '../demo/in_memory_dashboard_repository.dart';
import '../demo/in_memory_group_repository.dart';
import '../demo/in_memory_user_repository.dart';
import '../features/all_features.dart';
import '../features/feature_registry.dart';

/// The app's shared, long-lived objects, created once at startup.
///
/// This is the one place that decides which implementations the app uses
/// (demo fakes today, server-backed ones later). Pages receive what they
/// need from here through their constructors.
class AppDependencies {
  AppDependencies({
    required this.api,
    required this.features,
    required this.session,
    required this.dashboardRepository,
  });

  /// Wires the in-memory demo data. Replace with a `live()` factory once the
  /// server provides users and groups.
  static Future<AppDependencies> demo({required ApiClient api}) async {
    final session = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(),
    );
    await session.restore();
    return AppDependencies(
      api: api,
      features: buildFeatureRegistry(),
      session: session,
      dashboardRepository: InMemoryDashboardRepository(),
    );
  }

  final ApiClient api;
  final FeatureRegistry features;
  final SessionController session;
  final DashboardRepository dashboardRepository;
}
