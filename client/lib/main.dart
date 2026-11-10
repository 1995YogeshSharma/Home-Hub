import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'api/api_client.dart';
import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'config.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  // Required before doing async work ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Web: /home instead of /#/home. Does nothing on Android/iOS.
  usePathUrlStrategy();
  final deps = await AppDependencies.demo(
    api: ApiClient(baseUrl: AppConfig.apiBaseUrl),
  );
  runApp(HomeHubApp(router: createRouter(deps: deps)));
}
