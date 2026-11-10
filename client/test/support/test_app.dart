import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_hub_client/api/api_client.dart';
import 'package:home_hub_client/app/app.dart';
import 'package:home_hub_client/app/app_dependencies.dart';
import 'package:home_hub_client/core/models/user.dart';
import 'package:home_hub_client/core/session/session_controller.dart';
import 'package:home_hub_client/demo/demo_data.dart';
import 'package:home_hub_client/demo/in_memory_dashboard_repository.dart';
import 'package:home_hub_client/demo/in_memory_group_repository.dart';
import 'package:home_hub_client/demo/in_memory_user_repository.dart';
import 'package:home_hub_client/features/all_features.dart';
import 'package:home_hub_client/routing/app_router.dart';
import 'package:home_hub_client/routing/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// An [ApiClient] whose "server" always answers 200 with a small JSON body.
ApiClient fakeApi() => ApiClient(
  baseUrl: 'http://server.test:8000',
  httpClient: MockClient((_) async => http.Response('{"ok": true}', 200)),
);

/// App dependencies wired with fakes only. [user] is who is signed in.
Future<AppDependencies> testDependencies({User? user = DemoData.asha}) async {
  final session = SessionController(
    users: InMemoryUserRepository(signedIn: user),
    groups: InMemoryGroupRepository(),
  );
  await session.restore();
  return AppDependencies(
    api: fakeApi(),
    features: buildFeatureRegistry(),
    session: session,
    dashboardRepository: InMemoryDashboardRepository(),
  );
}

/// Builds a fresh router at [location], draws the whole app and returns the
/// router so tests can check where they are.
Future<GoRouter> pumpRouterApp(
  WidgetTester tester, {
  String location = AppRoutes.home,
  AppDependencies? deps,
}) async {
  final router = createRouter(
    deps: deps ?? await testDependencies(),
    initialLocation: location,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(HomeHubApp(router: router));
  await tester.pumpAndSettle();
  return router;
}

/// The path the router is currently showing, e.g. `/home/features/notes`.
String currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;
