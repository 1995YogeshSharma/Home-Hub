import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/api/api_client.dart';
import 'package:home_hub_client/server_status/server_status_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _apiReturning(int status, String body) => ApiClient(
  baseUrl: 'http://server.test:8000',
  httpClient: MockClient((_) async => http.Response(body, status)),
);

void main() {
  testWidgets('shows Connected when server responds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ServerStatusPage(
          api: _apiReturning(200, '{"Hello": "Hello from home hub"}'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('Hello from home hub'), findsOneWidget);
  });

  testWidgets('shows Not connected on server error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ServerStatusPage(api: _apiReturning(500, 'boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not connected'), findsOneWidget);
  });
}
