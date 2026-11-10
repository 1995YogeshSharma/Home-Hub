import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/dashboard/dashboard_page.dart';
import 'package:home_hub_client/demo/demo_data.dart';
import 'package:home_hub_client/routing/app_routes.dart';
import 'package:home_hub_client/server_status/server_status_page.dart';

import '../support/test_app.dart';

Future<void> _addViaPicker(WidgetTester tester, String title) async {
  await tester.tap(find.byKey(DashboardPage.addTileKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app bar shows the active group and who I am', (tester) async {
    await pumpRouterApp(tester);

    expect(find.text('Sharma Family'), findsOneWidget);
    expect(find.text('Asha · Admin'), findsOneWidget);
  });

  testWidgets('a member sees their role', (tester) async {
    await pumpRouterApp(
      tester,
      deps: await testDependencies(user: DemoData.ravi),
    );

    expect(find.text('Ravi · Member'), findsOneWidget);
  });

  testWidgets('shows a tile per default feature plus the add tile', (
    tester,
  ) async {
    await pumpRouterApp(tester);

    expect(find.byKey(DashboardPage.tileKey('notes')), findsOneWidget);
    expect(find.byKey(DashboardPage.tileKey('reminders')), findsOneWidget);
    expect(find.byKey(DashboardPage.tileKey('vault')), findsNothing);
    expect(find.byKey(DashboardPage.addTileKey), findsOneWidget);
  });

  testWidgets('tapping a tile opens its feature', (tester) async {
    final router = await pumpRouterApp(tester);

    await tester.tap(find.byKey(DashboardPage.tileKey('notes')));
    await tester.pumpAndSettle();

    expect(currentPath(router), AppRoutes.feature('notes'));
    expect(find.text('Notes is coming soon'), findsOneWidget);
  });

  testWidgets('the add tile offers only modules not yet pinned', (
    tester,
  ) async {
    await pumpRouterApp(tester);

    await tester.tap(find.byKey(DashboardPage.addTileKey));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    Finder inSheet(String title) =>
        find.descendant(of: sheet, matching: find.text(title));
    expect(inSheet('Vault'), findsOneWidget);
    expect(inSheet('Pictures'), findsOneWidget);
    expect(inSheet('Files'), findsOneWidget);
    expect(inSheet('Notes'), findsNothing);
    expect(inSheet('Reminders'), findsNothing);
  });

  testWidgets('picking a module adds its tile', (tester) async {
    await pumpRouterApp(tester);

    await _addViaPicker(tester, 'Vault');

    expect(find.byKey(DashboardPage.tileKey('vault')), findsOneWidget);
  });

  testWidgets('the add tile disappears when everything is pinned', (
    tester,
  ) async {
    await pumpRouterApp(tester);

    await _addViaPicker(tester, 'Vault');
    await _addViaPicker(tester, 'Pictures');
    await _addViaPicker(tester, 'Files');

    expect(find.byKey(DashboardPage.addTileKey), findsNothing);
  });

  testWidgets('the cloud icon opens server status', (tester) async {
    final router = await pumpRouterApp(tester);

    await tester.tap(find.byTooltip('Server status'));
    await tester.pumpAndSettle();

    expect(currentPath(router), AppRoutes.status);
    expect(find.byType(ServerStatusPage), findsOneWidget);
  });
}
