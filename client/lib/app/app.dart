import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root widget: theme plus the router that decides which page is shown.
class HomeHubApp extends StatelessWidget {
  const HomeHubApp({super.key, required this.router});

  /// Created once, outside `build`, so rebuilding never resets navigation.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Home Hub',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      routerConfig: router,
    );
  }
}
