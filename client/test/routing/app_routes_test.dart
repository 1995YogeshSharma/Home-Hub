import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/routing/app_routes.dart';

void main() {
  test('top-level paths', () {
    expect(AppRoutes.root, '/');
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.status, '/home/status');
  });

  test('feature paths live under /home/features', () {
    expect(AppRoutes.feature('notes'), '/home/features/notes');
  });
}
