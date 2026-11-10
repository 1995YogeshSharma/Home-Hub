import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';

/// Shown for any URL that no route matches.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.location});

  /// The URL the user tried to open.
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nothing lives at $location'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
