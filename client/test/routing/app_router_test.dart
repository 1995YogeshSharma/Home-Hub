import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/ui/not_found_page.dart';
import 'package:home_hub_client/dashboard/dashboard_page.dart';
import 'package:home_hub_client/features/all_features.dart';
import 'package:home_hub_client/routing/app_routes.dart';
import 'package:home_hub_client/server_status/server_status_page.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('/home shows the dashboard', (tester) async {
    final router = await pumpRouterApp(tester, location: AppRoutes.home);

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(currentPath(router), AppRoutes.home);
  });

  testWidgets('/ redirects to /home', (tester) async {
    final router = await pumpRouterApp(tester, location: AppRoutes.root);

    expect(currentPath(router), AppRoutes.home);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('/home/status sits on top of the dashboard', (tester) async {
    final router = await pumpRouterApp(tester, location: AppRoutes.status);

    expect(find.byType(ServerStatusPage), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(currentPath(router), AppRoutes.home);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('unknown URL shows not-found page with a way home', (
    tester,
  ) async {
    final router = await pumpRouterApp(tester, location: '/xyz');

    expect(find.byType(NotFoundPage), findsOneWidget);

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(currentPath(router), AppRoutes.home);
  });

  testWidgets('deep link to a feature stacks it on the dashboard', (
    tester,
  ) async {
    final router = await pumpRouterApp(
      tester,
      location: AppRoutes.feature('notes'),
    );

    expect(find.text('Notes is coming soon'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(currentPath(router), AppRoutes.home);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  for (final module in buildFeatureRegistry().all) {
    testWidgets('${module.id} is reachable at its URL', (tester) async {
      final router = await pumpRouterApp(
        tester,
        location: AppRoutes.feature(module.id),
      );

      expect(currentPath(router), '/home/features/${module.id}');
      expect(find.byType(NotFoundPage), findsNothing);
      expect(find.text(module.title), findsWidgets);
    });
  }

  for (final bad in [
    '/home/features/nope',
    '/home/features',
    '/home/features/Notes',
  ]) {
    testWidgets('$bad shows the not-found page', (tester) async {
      await pumpRouterApp(tester, location: bad);

      expect(find.byType(NotFoundPage), findsOneWidget);
    });
  }
}
