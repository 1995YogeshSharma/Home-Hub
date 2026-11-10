# Home Hub client: go_router, dashboard and core scaffolding

### A step-by-step TDD guide for a Flutter beginner

This guide is a plan. You write the code, run the tests, and commit when you are happy.

---

## 1. Overview

### 1.1 What we are building

- **`/home` is the dashboard.** It shows a grid of tiles, one per feature you pinned, and a **+** tile that adds more. Each person has their own layout inside each group. Asha's "Sharma Family" dashboard can differ from her "Book Club" dashboard, and from Ravi's.
- **Every feature lives at `/home/features/<feature-id>`**, for example `/home/features/notes`. Each feature is a small *module* listed once in a *registry*. The router, the dashboard tile and the **+** picker are all generated from that one list.
- **Users and groups are real, typed concepts from day one**: `User`, `Group`, `GroupRole` (admin/member), `Membership` and `Session`. Dummy data comes from *repositories*. Today those are in-memory fakes. Later, onboarding and the server will provide real ones, and the UI will not change.
- **Onboarding comes later.** The session is already a `ChangeNotifier`, and the session is `null` when "nobody is signed in" or "this user has no group yet". Section 6 shows the redirect guard you will add then.
- **The existing `ServerStatusPage` is kept.** It moves to its own file, lives at `/home/status`, and opens from a cloud icon on the dashboard.

### 1.2 Route tree

```
/                               redirect only  →  /home        (later: welcome/onboarding)
/home                           DashboardPage
  ├── status                    /home/status              ServerStatusPage
  ├── features/notes            /home/features/notes      notesModule.pageBuilder
  ├── features/reminders        /home/features/reminders  "coming soon"
  ├── features/vault            /home/features/vault      "coming soon"
  ├── features/pictures         /home/features/pictures   "coming soon"
  └── features/files            /home/features/files      "coming soon"
        └── (later) a module's own sub-routes, e.g. notes/:noteId
anything else                   errorBuilder  →  NotFoundPage   (/xyz, /home/features, /home/features/Notes, ...)
```

Every page is a *child* of `/home`. Opening `/home/features/notes`, even straight from the browser address bar, therefore builds the stack `[Dashboard, Notes]`. You get a back arrow that returns to the dashboard for free.

### 1.3 Folder structure (final state)

```
client/
  nginx.conf                                  NEW   web: send unknown paths to index.html
  Dockerfile                                  EDIT  one COPY line for nginx.conf
  pubspec.yaml / pubspec.lock                 EDIT  go_router, flutter_web_plugins
  lib/
    main.dart                                 EDIT  startup only
    config.dart                               unchanged
    api/api_client.dart                       unchanged
    app/
      app.dart                                HomeHubApp (MaterialApp.router)
      app_dependencies.dart                   AppDependencies: the ONE place that picks implementations
    routing/
      app_routes.dart                         AppRoutes: every path string
      app_router.dart                         createRouter(): the route tree
    core/                                     shared by every module: identity, groups, roles, session
      models/user.dart
      models/group.dart                       Group, GroupRole, Membership
      models/session.dart
      repositories/user_repository.dart       abstract interface
      repositories/group_repository.dart      abstract interface
      session/session_controller.dart         SessionController (ChangeNotifier)
      ui/not_found_page.dart
      ui/coming_soon_page.dart
    features/
      feature_module.dart                     the plug-in contract
      feature_registry.dart                   validates + looks up modules
      all_features.dart                       THE list of modules
      notes/notes_module.dart
    dashboard/
      dashboard_repository.dart               abstract interface (pinned tiles per user+group)
      dashboard_view_model.dart
      dashboard_page.dart
      widgets/feature_tile.dart
      widgets/add_feature_tile.dart
    demo/                                     everything fake lives here and nowhere else
      demo_data.dart
      in_memory_user_repository.dart
      in_memory_group_repository.dart
      in_memory_dashboard_repository.dart
    server_status/
      server_status_page.dart                 MOVED out of main.dart
  test/                                       mirrors lib/
    support/test_app.dart                     shared helpers (not a test file itself)
    server_status/server_status_page_test.dart   replaces widget_test.dart
    routing/app_routes_test.dart
    routing/app_router_test.dart
    features/feature_registry_test.dart
    core/models/session_test.dart
    demo/in_memory_repositories_test.dart
    core/session/session_controller_test.dart
    demo/in_memory_dashboard_repository_test.dart
    dashboard/dashboard_view_model_test.dart
    dashboard/dashboard_page_test.dart
```

Two rules keep this clean:
1. Only `app/app_dependencies.dart` and `test/` may import anything from `demo/`.
2. Pages never create repositories. They receive them.

### 1.4 Key decisions and why

| Decision | Choice | Why |
|---|---|---|
| Router | **`go_router: ^17.5.0`** | go_router is the router Flutter officially recommends. go_router **18** forces moving the whole app from `package:flutter/material.dart` to the new `material_ui`/`cupertino_ui` packages. On our Flutter **3.44** Docker image, `material_ui` is capped at 1.2.0, and almost every tutorial you will read still uses `flutter/material.dart`. 17.5 needs Dart 3.10, and we have ^3.12. go_router is feature-complete, so we lose nothing. The move to 18 is a separate change later (section 6.6). |
| Clean web URLs | **`flutter_web_plugins` (sdk: flutter)** | Gives `usePathUrlStrategy()`, so URLs are `/home/features/notes` instead of `/#/home/features/notes`. It does nothing on mobile. |
| State | **`ChangeNotifier` + `ListenableBuilder`** (built into Flutter) | One idea to learn ("an object that announces changes"). Flutter's architecture guide uses this MVVM style. |
| Dependency injection | **Constructor injection from one `AppDependencies` object**, no package | Same style as your `ApiClient(baseUrl:, httpClient:)`. Add `provider ^6.1.5+1` later, if passing things down becomes painful. The switch is mechanical. |
| Typed routes / codegen | **None** (no go_router_builder, freezed, riverpod or mocktail) | No `build_runner` step to learn. An `AppRoutes` constants class plus router tests give most of the safety. |
| Feature routes | **One `GoRoute` per module, generated from the registry** | Unknown ids hit the 404 page automatically, and each module can own sub-routes (`notes/:noteId`). |
| The **+** picker | **A bottom sheet**, not a separate route | The dashboard's view model stays private to the page, and no state has to be shared between routes. |
| Tests | **Real `GoRouter` + in-memory fakes**, no mocks | Fewer concepts. The fakes are the same classes the demo app uses. |
| `ServerStatusPage` | **Kept**, moved to `lib/server_status/`, served at `/home/status` | It is a child of `/home`, so it gets a back arrow. Its two tests move with it. |

---

## 2. Concepts primer (just enough)

**Widget.** Everything on screen is a widget: text, a button, padding, a whole page. You build the UI by nesting widgets: `Scaffold(appBar: AppBar(...), body: Center(child: Text('Hi')))`. A **page** (or screen) is just a widget that a route shows. `Scaffold` is the standard page skeleton (app bar + body).

**`build()` and BuildContext.** Each widget has a `build(BuildContext context)` method that returns the widgets it is made of. Flutter calls `build` often, whenever something might have changed. So **never create long-lived objects inside `build`**, such as the router or a view model. `context` is the widget's "address" in the tree. You use it to find things above you, for example `Theme.of(context)`, or `context.go(...)` to reach the router.

**StatelessWidget vs StatefulWidget.**
- `StatelessWidget` has only `final` fields given by its parent, and it rebuilds when the parent rebuilds it.
- `StatefulWidget` comes with a separate `State` object that **survives rebuilds**. You create things once in `initState()`, clean up in `dispose()`, and call `setState(() {...})` to redraw. Your `ServerStatusPage` is already a StatefulWidget: it starts the HTTP call in `initState`.

**`const`.** `const Text('Hi')` means the object is built at compile time and reused. The linter will suggest `const` where it is possible. Just accept the suggestions.

**`Future` / `async` / `await`.** A `Future<T>` is a value that arrives later. Inside an `async` function, `await` pauses until it arrives. Repositories return Futures even when the data is instant, so a real server can be swapped in later without changing callers.

**go_router concepts.**
- **`GoRouter`** is the router object. It is created **once** and given to `MaterialApp.router(routerConfig: router)`.
- **`GoRoute(path:, builder:)`** means "this URL shows this page". `builder` is `(context, state) => SomePage()`.
- **Child routes** go in `routes: [...]`. They have *relative* paths with no leading `/`, for example `'status'` under `'/home'`, which means `/home/status`. Opening a child URL builds the parent page *and* the child page, so the back arrow works even after a deep link.
- **Path parameters:** `GoRoute(path: ':noteId', ...)` matches `/home/features/notes/abc`, and you read the value with `state.pathParameters['noteId']`.
- **`context.go('/home/features/notes')`** means "make the screen match this URL". **Use it everywhere.**
- **`context.push(...)`** adds a screen without giving it its own URL. Such screens are not deep-linkable and confuse browser history, so we don't use it for pages.
- **`redirect`** is a function that runs before navigation. Return `null` for "carry on", or a path for "go there instead". We use it on `/` now, and globally for sign-in later.
- **`errorBuilder`** is the page shown when no route matches (our 404 page).
- URL matching is **case-sensitive**: `/home/features/Notes` is a 404. That is why module ids must be lowercase.

**State with ChangeNotifier.** A `ChangeNotifier` is an object that holds state and calls `notifyListeners()` when the state changes. `ListenableBuilder(listenable: vm, builder: ...)` re-runs its builder each time that happens. A **view model** is a ChangeNotifier that holds a page's logic, so the widget only draws.

**Dependency injection (our flavour).** Objects are created in one place (`AppDependencies`) and handed to whoever needs them through constructors. Tests hand in fakes. That is all "DI" means here.

**Testing words.**
- `test(...)` is a plain Dart test.
- `testWidgets(...)` gives you a `tester` that draws widgets on a fake screen.
- `tester.pumpWidget(w)` puts a widget on that screen.
- `tester.pumpAndSettle()` keeps drawing frames until animations and navigation finish. Call it after every tap.
- `find.text`, `find.byType`, `find.byKey` and `find.byTooltip` locate widgets.
- `expect(finder, findsOneWidget)` (or `findsNothing`) checks them.

---

## 3. Environment

Your Docker image uses **Flutter 3.44.0**. Use the same version locally, so `pubspec.lock` and test results match what the Docker build does.

### Option A (recommended): install Flutter 3.44.0 on macOS

```sh
mkdir -p ~/development
git clone --depth 1 --branch 3.44.0 https://github.com/flutter/flutter.git ~/development/flutter
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
flutter --version      # should say Flutter 3.44.0 ... Dart 3.12.x
flutter doctor         # Xcode/Android warnings are fine; you only need the Dart/Flutter parts for tests
```

Notes:
- `brew install --cask flutter` would install the *latest* (3.47.x), which differs from the Docker image, so avoid it.
- If you prefer a version manager, use `brew tap leoafarias/fvm && brew install fvm`, then `cd client && fvm use 3.44.0`, and prefix every command with `fvm` (`fvm flutter test`). If you do this, add `.fvm/` to `client/.dockerignore`.
- Running the app in a browser (`flutter run -d chrome`) needs Google Chrome. Tests do not.
- For editor support, install VS Code with the "Flutter" extension. It shows red squiggles and runs tests.

### Option B: run everything inside the Docker build image (nothing installed)

Run this from the repo root:

```sh
alias ft='docker run --rm -v /Users/ysharma/home_hub/client:/src -w /src ghcr.io/cirruslabs/flutter:3.44.0'
ft sh -c "flutter pub get && flutter analyze && flutter test"
```

Notes:
- Flutter prints a warning about running as root. That is expected; ignore it.
- Each run re-downloads packages. To cache them, find the image's pub-cache path with `ft sh -c 'echo ${PUB_CACHE:-$HOME/.pub-cache}'` and add `-v home_hub_pub_cache:<that path>` to the alias.

### The commands you will use (run from `/Users/ysharma/home_hub/client`)

| Command | What it does |
|---|---|
| `flutter pub add go_router:^17.5.0` | Adds a package to pubspec.yaml **and** updates pubspec.lock |
| `flutter pub get` | Re-resolves packages. **Run it after any hand edit to pubspec.yaml.** The Dockerfile copies `pubspec.lock`, so a stale lock breaks the image build. |
| `flutter test` | Runs every `*_test.dart` under `test/` |
| `flutter test test/routing/app_router_test.dart` | Runs one file |
| `flutter test --name "redirects"` | Runs tests whose name contains "redirects" |
| `flutter analyze` | Lints and type-checks. It must say "No issues found!" |
| `dart format .` | Formats all code (don't hand-align anything) |

**Check before you start:** run `flutter test` on the untouched repo. You should see the 2 existing tests pass.

**The TDD rhythm for every step:**
1. Write the test.
2. Run it and watch it **fail** (red). A compile error such as "Undefined name" counts as red.
3. Write the least code that makes it pass (green).
4. Run `dart format . && flutter analyze && flutter test`. Everything must stay green.

---

## 4. TDD steps

### Step 1: move `ServerStatusPage` into its own file (refactor warm-up)

**Goal:** practise the loop on code you already have. A *refactor* changes structure, not behaviour, so the tests keep the same meaning.

**Files:**
- new `test/server_status/server_status_page_test.dart`
- new `lib/server_status/server_status_page.dart`
- edit `lib/main.dart`
- delete `test/widget_test.dart`

**Test first.** Create `test/server_status/server_status_page_test.dart`, then delete `test/widget_test.dart`:

```dart
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
```

**See it fail:** `flutter test test/server_status`. You get a compile error such as *"Error when reading 'lib/server_status/server_status_page.dart': No such file or directory"* (your editor calls it *"Target of URI doesn't exist"*).

**Make it pass.**
1. Create `lib/server_status/server_status_page.dart`.
2. Cut the whole `ServerStatusPage` and `_ServerStatusPageState` code out of `main.dart` and paste it in, unchanged.
3. Add these imports at the top:

```dart
import 'package:flutter/material.dart';

import '../api/api_client.dart';
```

`lib/main.dart` is now:

```dart
import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'config.dart';
import 'server_status/server_status_page.dart';

void main() {
  runApp(MainApp(api: ApiClient(baseUrl: AppConfig.apiBaseUrl)));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Hub',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: ServerStatusPage(api: api),
    );
  }
}
```

Run `flutter test`: 2 tests pass.

**Concepts:**
- `MaterialApp` provides the theme, text direction and navigator that pages need. The test wraps the page in a bare `MaterialApp(home: ...)` so the page can be tested on its own.
- `MockClient` is a fake HTTP client. No network is used in tests.

---

### Step 2: add the packages and the `AppRoutes` paths

**Goal:** packages in place, plus one tiny pure-Dart test to learn `test()`.

**Packages:**
1. Run `flutter pub add go_router:^17.5.0`.
2. Edit `pubspec.yaml` by hand to add `flutter_web_plugins`, (or run `flutter pub add flutter_web_plugins --sdk=flutter`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter
  go_router: ^17.5.0
  http: ^1.6.0
```

3. Run `flutter pub get`, then `flutter test`. Still 2 tests, still green.

**Files:**
- new `test/routing/app_routes_test.dart`
- new `lib/routing/app_routes.dart`

**Test first:**

```dart
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
```

**See it fail:** `flutter test test/routing/app_routes_test.dart`. You get "Error when reading 'lib/routing/app_routes.dart': No such file or directory".

**Make it pass.** `lib/routing/app_routes.dart`:

```dart
/// Every URL in the app, so no screen hard-codes a path string.
///
/// Navigate with these, e.g. `context.go(AppRoutes.feature('notes'))`.
abstract final class AppRoutes {
  static const root = '/';
  static const home = '/home';
  static const status = '/home/status';

  /// The page of the feature module with [featureId], e.g. `/home/features/notes`.
  static String feature(String featureId) => '/home/features/$featureId';
}
```

**Concepts:**
- `abstract final class` means "nobody can create or subclass this". It is just a namespace for constants.
- `$featureId` inside a string inserts the variable's value (string interpolation).

---

### Step 3: the first router (`/` → `/home`, `/home/status`, 404)

**Goal:** go_router running, with a placeholder dashboard. After this step the real app uses the router.

**Files:**
- new `test/support/test_app.dart`
- new `test/routing/app_router_test.dart`
- new `lib/app/app_dependencies.dart`
- new `lib/app/app.dart`
- new `lib/routing/app_router.dart`
- new `lib/dashboard/dashboard_page.dart`
- new `lib/core/ui/not_found_page.dart`
- edit `lib/main.dart`

**Test helper first.** `test/support/test_app.dart` is not a test itself, because its name does not end in `_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_hub_client/api/api_client.dart';
import 'package:home_hub_client/app/app.dart';
import 'package:home_hub_client/app/app_dependencies.dart';
import 'package:home_hub_client/routing/app_router.dart';
import 'package:home_hub_client/routing/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// An [ApiClient] whose "server" always answers 200 with a small JSON body.
ApiClient fakeApi() => ApiClient(
  baseUrl: 'http://server.test:8000',
  httpClient: MockClient((_) async => http.Response('{"ok": true}', 200)),
);

/// App dependencies wired with fakes only: no network, no real server.
Future<AppDependencies> testDependencies() async {
  return AppDependencies(api: fakeApi());
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
```

**Tests.** `test/routing/app_router_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/ui/not_found_page.dart';
import 'package:home_hub_client/dashboard/dashboard_page.dart';
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
}
```

**See it fail:** `flutter test test/routing`. Several names are undefined. You may also see a scary "Dart compiler exited unexpectedly" for `app_routes_test.dart`. That is a side effect of the other file not compiling, and it goes away once it does.

**Make it pass.**

`lib/app/app_dependencies.dart`:

```dart
import '../api/api_client.dart';

/// The app's shared, long-lived objects, created once at startup.
///
/// This is the one place that decides which implementations the app uses
/// (demo fakes today, server-backed ones later). Pages receive what they
/// need from here through their constructors.
class AppDependencies {
  AppDependencies({required this.api});

  final ApiClient api;
}
```

`lib/app/app.dart`:

```dart
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
```

`lib/routing/app_router.dart`:

```dart
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
        builder: (context, state) => const DashboardPage(),
        // Child paths are relative: 'status' means /home/status.
        routes: [
          GoRoute(
            path: 'status',
            builder: (context, state) => ServerStatusPage(api: deps.api),
          ),
        ],
      ),
    ],
  );
}
```

`lib/dashboard/dashboard_page.dart` (a placeholder for now):

```dart
import 'package:flutter/material.dart';

/// The home dashboard at `/home`.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Hub')),
      body: const Center(child: Text('Dashboard')),
    );
  }
}
```

`lib/core/ui/not_found_page.dart`:

```dart
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
```

`lib/main.dart` (`MainApp` is gone):

```dart
import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'config.dart';
import 'routing/app_router.dart';

void main() {
  final deps = AppDependencies(api: ApiClient(baseUrl: AppConfig.apiBaseUrl));
  runApp(HomeHubApp(router: createRouter(deps: deps)));
}
```

**Concepts:**
- `MaterialApp.router` is the router version of `MaterialApp`: the router picks the pages.
- `(_, _)` means "I ignore both parameters".
- The `BackButton` appears automatically in the `AppBar` because `/home/status` is a child of `/home`, so there is a page underneath to go back to.
- `addTearDown(router.dispose)` cleans up after each test.
- **Pitfall:** never write `createRouter(...)` inside a `build` method. Every rebuild would reset navigation to the start.

---

### Step 4: feature modules and the registry

**Goal:** describe each module (id, title, icon, page) once, and validate the list.

**Files:**
- new `test/features/feature_registry_test.dart`
- new `lib/features/feature_module.dart`
- new `lib/features/feature_registry.dart`
- new `lib/features/all_features.dart`
- new `lib/features/notes/notes_module.dart`
- new `lib/core/ui/coming_soon_page.dart`

**Test first:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/features/all_features.dart';
import 'package:home_hub_client/features/feature_module.dart';
import 'package:home_hub_client/features/feature_registry.dart';

FeatureModule _module(String id, {bool pinned = false}) => FeatureModule(
  id: id,
  title: id,
  icon: Icons.circle,
  pinnedByDefault: pinned,
  pageBuilder: (_, _) => const SizedBox(),
);

void main() {
  test('byId finds a module and returns null for unknown ids', () {
    final registry = FeatureRegistry([_module('notes'), _module('files')]);

    expect(registry.byId('files')?.id, 'files');
    expect(registry.byId('nope'), isNull);
  });

  test('rejects duplicate ids', () {
    expect(
      () => FeatureRegistry([_module('notes'), _module('notes')]),
      throwsArgumentError,
    );
  });

  test('rejects ids that are not lowercase url slugs', () {
    expect(() => FeatureRegistry([_module('Notes')]), throwsArgumentError);
    expect(() => FeatureRegistry([_module('my/notes')]), throwsArgumentError);
    expect(() => FeatureRegistry([_module('')]), throwsArgumentError);
  });

  test('defaultPinnedIds keeps registry order', () {
    final registry = FeatureRegistry([
      _module('b', pinned: true),
      _module('a'),
      _module('c', pinned: true),
    ]);

    expect(registry.defaultPinnedIds, ['b', 'c']);
  });

  test('the list of modules cannot be changed from outside', () {
    final registry = FeatureRegistry([_module('notes')]);

    expect(() => registry.all.add(_module('x')), throwsUnsupportedError);
  });

  test('the app ships notes, reminders, vault, pictures and files', () {
    final registry = buildFeatureRegistry();

    expect(registry.all.map((m) => m.id).toList(), [
      'notes',
      'reminders',
      'vault',
      'pictures',
      'files',
    ]);
    expect(registry.defaultPinnedIds, ['notes', 'reminders']);
  });
}
```

**See it fail:** `flutter test test/features`.

**Make it pass.**

`lib/features/feature_module.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// One plug-in module (Notes, Vault, ...) as the app shell sees it.
///
/// From this description alone the shell builds the module's route
/// (`/home/features/<id>`), its dashboard tile and its entry in the '+' picker.
class FeatureModule {
  const FeatureModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.pageBuilder,
    this.pinnedByDefault = false,
    this.routes = const [],
  });

  /// Lowercase URL slug, e.g. `notes`.
  ///
  /// Also the key in saved dashboards, so never rename it.
  final String id;

  final String title;
  final IconData icon;

  /// Builds the module's main page. Gets the [GoRouterState] so a page can
  /// read path or query parameters.
  final GoRouterWidgetBuilder pageBuilder;

  /// Whether a dashboard shows this module before the user customises it.
  final bool pinnedByDefault;

  /// Optional nested routes, relative to the module's own path
  /// (e.g. `':noteId'` for `/home/features/notes/<noteId>`).
  final List<RouteBase> routes;
}
```

`lib/features/feature_registry.dart`:

```dart
import 'feature_module.dart';

/// The fixed set of modules the app ships with.
class FeatureRegistry {
  /// Throws [ArgumentError] if an id is duplicated or is not a lowercase slug.
  FeatureRegistry(List<FeatureModule> modules)
    : all = List.unmodifiable(modules) {
    final seen = <String>{};
    for (final module in modules) {
      if (!_idPattern.hasMatch(module.id)) {
        throw ArgumentError.value(module.id, 'id', 'must be a lowercase slug');
      }
      if (!seen.add(module.id)) {
        throw ArgumentError.value(module.id, 'id', 'is used more than once');
      }
    }
  }

  // URLs are case-sensitive, so ids are lowercase letters, digits and '-'.
  static final _idPattern = RegExp(r'^[a-z][a-z0-9-]*$');

  /// Every module, in display order.
  final List<FeatureModule> all;

  /// The module with [id], or null if there is none.
  FeatureModule? byId(String id) {
    for (final module in all) {
      if (module.id == id) return module;
    }
    return null;
  }

  /// Ids shown on a dashboard nobody has customised yet.
  List<String> get defaultPinnedIds => [
    for (final module in all)
      if (module.pinnedByDefault) module.id,
  ];
}
```

`lib/core/ui/coming_soon_page.dart`:

```dart
import 'package:flutter/material.dart';

/// Placeholder page for a module that is not built yet.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title is coming soon')),
    );
  }
}
```

`lib/features/notes/notes_module.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/ui/coming_soon_page.dart';
import '../feature_module.dart';

/// Shared notes for the group. The first module to get a real page.
final notesModule = FeatureModule(
  id: 'notes',
  title: 'Notes',
  icon: Icons.sticky_note_2_outlined,
  pinnedByDefault: true,
  pageBuilder: (context, state) => const ComingSoonPage(title: 'Notes'),
);
```

`lib/features/all_features.dart`:

```dart
import 'package:flutter/material.dart';

import '../core/ui/coming_soon_page.dart';
import 'feature_module.dart';
import 'feature_registry.dart';
import 'notes/notes_module.dart';

/// The single list of modules. Adding a module = one entry here.
FeatureRegistry buildFeatureRegistry() => FeatureRegistry([
  notesModule,
  _comingSoon(
    id: 'reminders',
    title: 'Reminders',
    icon: Icons.alarm,
    pinnedByDefault: true,
  ),
  _comingSoon(id: 'vault', title: 'Vault', icon: Icons.lock_outline),
  _comingSoon(
    id: 'pictures',
    title: 'Pictures',
    icon: Icons.photo_library_outlined,
  ),
  _comingSoon(id: 'files', title: 'Files', icon: Icons.folder_outlined),
]);

/// A module with no real page yet. Move it to `features/<id>/` when built.
FeatureModule _comingSoon({
  required String id,
  required String title,
  required IconData icon,
  bool pinnedByDefault = false,
}) => FeatureModule(
  id: id,
  title: title,
  icon: icon,
  pinnedByDefault: pinnedByDefault,
  pageBuilder: (_, _) => ComingSoonPage(title: title),
);
```

**Concepts:**
- `final` fields plus a `const` constructor make an *immutable* object: you never change it, you make a new one.
- `GoRouterWidgetBuilder` is go_router's name for the type `Widget Function(BuildContext, GoRouterState)`.
- `[for (...) if (...) x]` is a *collection-for*: it builds a list inline.
- Copy rule: placeholder pages only say "coming soon". There must be no "encrypted" or "secure" claims for Vault until that is built.

---

### Step 5: generate the feature routes

**Goal:** `/home/features/<id>` works for every module. Unknown, uppercase or bare `/home/features` URLs show the 404 page.

**Files:**
- edit `lib/app/app_dependencies.dart`
- edit `test/support/test_app.dart`
- edit `lib/routing/app_router.dart`
- edit `lib/main.dart`
- add tests to `test/routing/app_router_test.dart`

**Tests first.** Add these imports to `app_router_test.dart`:

```dart
import 'package:home_hub_client/features/all_features.dart';
```

Add these tests inside `main()`:

```dart
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
```

**See it fail:** `flutter test test/routing/app_router_test.dart`. The feature URLs show `NotFoundPage`.

Note: the 6 feature-URL tests (5 "reachable", plus "deep link") fail red. The 3 bad-URL tests are already green. They are guard tests that keep the 404 behaviour from regressing once the feature routes exist. That is expected.

**Make it pass.**

`lib/app/app_dependencies.dart`:

```dart
import '../api/api_client.dart';
import '../features/feature_registry.dart';

/// The app's shared, long-lived objects, created once at startup.
///
/// This is the one place that decides which implementations the app uses
/// (demo fakes today, server-backed ones later). Pages receive what they
/// need from here through their constructors.
class AppDependencies {
  AppDependencies({required this.api, required this.features});

  final ApiClient api;
  final FeatureRegistry features;
}
```

In `test/support/test_app.dart`:
1. Add `import 'package:home_hub_client/features/all_features.dart';`.
2. Change `testDependencies` to:

```dart
Future<AppDependencies> testDependencies() async {
  return AppDependencies(api: fakeApi(), features: buildFeatureRegistry());
}
```

In `lib/routing/app_router.dart`, add the generated routes after the `status` route:

```dart
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
```

In `lib/main.dart`:
1. Add `import 'features/all_features.dart';`.
2. Build the dependencies with:

```dart
  final deps = AppDependencies(
    api: ApiClient(baseUrl: AppConfig.apiBaseUrl),
    features: buildFeatureRegistry(),
  );
```

**Concepts:**
- **Why not one `features/:featureId` route?** With a parameter, every unknown id would need hand-written "not found" code, and modules couldn't own sub-routes.
- **Gotcha:** do **not** add a parent `GoRoute(path: 'features', redirect: ...)` to "catch" bare `/home/features`. A route's redirect also runs for all its children, so it would bounce `/home/features/notes` too. Leave `/home/features` unmatched (a 404).
- `for` *outside* a test registers one test per module. A new module gets tested automatically.

---

### Step 6: domain models (User, Group, GroupRole, Membership, Session)

**Goal:** "group comes first" in types. Data belongs to a group, and a user reaches it through a membership with a role.

**Files:**
- new `test/core/models/session_test.dart`
- new `lib/core/models/user.dart`
- new `lib/core/models/group.dart`
- new `lib/core/models/session.dart`

**Test first:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/core/models/session.dart';
import 'package:home_hub_client/core/models/user.dart';

const _asha = User(id: 'u-asha', displayName: 'Asha');
const _family = Group(code: 'sharma-family', name: 'Sharma Family');
const _club = Group(code: 'book-club', name: 'Book Club');
const _adminOfFamily = Membership(
  userId: 'u-asha',
  group: _family,
  role: GroupRole.admin,
);
const _memberOfClub = Membership(
  userId: 'u-asha',
  group: _club,
  role: GroupRole.member,
);

void main() {
  test('GroupRole knows admins and has a label', () {
    expect(GroupRole.admin.isAdmin, isTrue);
    expect(GroupRole.member.isAdmin, isFalse);
    expect(GroupRole.admin.label, 'Admin');
    expect(GroupRole.member.label, 'Member');
  });

  test('group and role come from the active membership', () {
    final session = Session(
      user: _asha,
      memberships: [_adminOfFamily, _memberOfClub],
      active: _memberOfClub,
    );

    expect(session.group.name, 'Book Club');
    expect(session.role, GroupRole.member);
    expect(session.isAdmin, isFalse);
  });

  test('the same user can be admin in another group', () {
    final session = Session(
      user: _asha,
      memberships: [_adminOfFamily, _memberOfClub],
      active: _adminOfFamily,
    );

    expect(session.isAdmin, isTrue);
  });

  test('memberships cannot be changed from outside', () {
    final session = Session(
      user: _asha,
      memberships: [_adminOfFamily],
      active: _adminOfFamily,
    );

    expect(
      () => session.memberships.add(_memberOfClub),
      throwsUnsupportedError,
    );
  });

  test('the active membership must be one of the memberships', () {
    expect(
      () => Session(
        user: _asha,
        memberships: [_adminOfFamily],
        active: _memberOfClub,
      ),
      throwsAssertionError,
    );
  });
}
```

**See it fail:** `flutter test test/core`.

**Make it pass.**

`lib/core/models/user.dart`:

```dart
/// A person using Home Hub.
class User {
  const User({required this.id, required this.displayName});

  /// Opaque id; a UUID string once the server provides users.
  final String id;

  final String displayName;
}
```

`lib/core/models/group.dart`:

```dart
/// What a user may do inside one group.
enum GroupRole {
  admin('Admin'),
  member('Member');

  const GroupRole(this.label);

  /// Human-readable name for the UI.
  final String label;

  bool get isAdmin => this == GroupRole.admin;
}

/// A household, family or team. Data in Home Hub belongs to a group.
class Group {
  const Group({required this.code, required this.name});

  /// Stable identifier; matches `GroupCode` in the server's schema.
  final String code;

  final String name;
}

/// One user's place in one group, and their role there.
class Membership {
  const Membership({
    required this.userId,
    required this.group,
    required this.role,
  });

  final String userId;
  final Group group;
  final GroupRole role;
}
```

`lib/core/models/session.dart`:

```dart
import 'group.dart';
import 'user.dart';

/// Who is signed in, and which group they are acting in right now.
class Session {
  Session({
    required this.user,
    required List<Membership> memberships,
    required this.active,
  }) : assert(
         memberships.contains(active),
         'active must be one of memberships',
       ),
       memberships = List.unmodifiable(memberships);

  final User user;

  /// Every group this user belongs to (for a group switcher later).
  final List<Membership> memberships;

  /// The group the user is acting in now, with their role in it.
  final Membership active;

  Group get group => active.group;
  GroupRole get role => active.role;
  bool get isAdmin => role.isAdmin;
}
```

**Concepts:**
- An **enum** is a fixed set of values. A `switch` over it must handle every value, so adding a role later makes the compiler point at every place that needs updating.
- `assert(...)` is a check that runs in tests and debug builds.
- The `: ...` part after the constructor's parameter list is the *initializer list*. It runs before the object exists, which is where you set `final` fields computed from parameters.

---

### Step 7: dummy data and in-memory repositories

**Goal:**
- *Repositories* are "where data comes from".
- We define them as interfaces, plus in-memory versions holding the demo people and groups.
- Asha is an **Admin** in Sharma Family and a **Member** in Book Club; Ravi is a Member in Sharma Family.

**Files:**
- new `test/demo/in_memory_repositories_test.dart`
- new `lib/core/repositories/user_repository.dart`
- new `lib/core/repositories/group_repository.dart`
- new `lib/demo/demo_data.dart`
- new `lib/demo/in_memory_user_repository.dart`
- new `lib/demo/in_memory_group_repository.dart`

**Test first:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/demo/demo_data.dart';
import 'package:home_hub_client/demo/in_memory_group_repository.dart';
import 'package:home_hub_client/demo/in_memory_user_repository.dart';

void main() {
  group('InMemoryUserRepository', () {
    test('Asha is signed in by default', () async {
      final user = await InMemoryUserRepository().currentUser();

      expect(user?.id, 'u-asha');
    });

    test('can simulate nobody signed in', () async {
      final repo = InMemoryUserRepository(signedIn: null);

      expect(await repo.currentUser(), isNull);
    });
  });

  group('InMemoryGroupRepository', () {
    test('Asha is admin of the family and member of the book club', () async {
      final memberships = await InMemoryGroupRepository().membershipsOf(
        'u-asha',
      );

      expect(memberships.map((m) => (m.group.code, m.role)).toList(), [
        ('sharma-family', GroupRole.admin),
        ('book-club', GroupRole.member),
      ]);
    });

    test('Ravi is a member of the family', () async {
      final memberships = await InMemoryGroupRepository().membershipsOf(
        DemoData.ravi.id,
      );

      expect(memberships.single.role, GroupRole.member);
    });

    test('an unknown user has no groups', () async {
      expect(await InMemoryGroupRepository().membershipsOf('nobody'), isEmpty);
    });
  });
}
```

**See it fail:** `flutter test test/demo`.

**Make it pass.**

`lib/core/repositories/user_repository.dart`:

```dart
import '../models/user.dart';

/// Where the signed-in user comes from (demo data today, the server later).
abstract interface class UserRepository {
  /// The signed-in user, or null when nobody is signed in.
  Future<User?> currentUser();
}
```

`lib/core/repositories/group_repository.dart`:

```dart
import '../models/group.dart';

/// Where group memberships come from (demo data today, the server later).
abstract interface class GroupRepository {
  /// Every group [userId] belongs to, in display order. Empty if none.
  Future<List<Membership>> membershipsOf(String userId);
}
```

`lib/demo/demo_data.dart`:

```dart
import '../core/models/group.dart';
import '../core/models/user.dart';

/// The only place fake people and groups exist.
abstract final class DemoData {
  static const asha = User(id: 'u-asha', displayName: 'Asha');
  static const ravi = User(id: 'u-ravi', displayName: 'Ravi');

  static const sharmaFamily = Group(
    code: 'sharma-family',
    name: 'Sharma Family',
  );
  static const bookClub = Group(code: 'book-club', name: 'Book Club');

  // String literals, because `asha.id` is not allowed in a const list.
  static const memberships = [
    Membership(userId: 'u-asha', group: sharmaFamily, role: GroupRole.admin),
    Membership(userId: 'u-asha', group: bookClub, role: GroupRole.member),
    Membership(userId: 'u-ravi', group: sharmaFamily, role: GroupRole.member),
  ];
}
```

`lib/demo/in_memory_user_repository.dart`:

```dart
import '../core/models/user.dart';
import '../core/repositories/user_repository.dart';
import 'demo_data.dart';

/// [UserRepository] backed by a fixed user. Pass `signedIn: null` to
/// simulate "nobody signed in".
class InMemoryUserRepository implements UserRepository {
  InMemoryUserRepository({this._signedIn = DemoData.asha});

  final User? _signedIn;

  @override
  Future<User?> currentUser() async => _signedIn;
}
```

`lib/demo/in_memory_group_repository.dart`:

```dart
import '../core/models/group.dart';
import '../core/repositories/group_repository.dart';
import 'demo_data.dart';

/// [GroupRepository] backed by a list of memberships (demo data by default).
class InMemoryGroupRepository implements GroupRepository {
  InMemoryGroupRepository({this._memberships = DemoData.memberships});

  final List<Membership> _memberships;

  @override
  Future<List<Membership>> membershipsOf(String userId) async => [
    for (final m in _memberships)
      if (m.userId == userId) m,
  ];
}
```

**Concepts:**
- `abstract interface class` is a contract: "anything that is a `UserRepository` has `currentUser()`".
- `implements` is how a class promises to fulfil it.
- `{this._signedIn = DemoData.asha}` is a **private named parameter**. Callers write `signedIn:`, the field stays private, and the value is stored straight into the field.
- `(a, b)` is a **record**, a quick pair of values that compares by content, which is handy in tests.
- **Rule:** fakes never use `Future.delayed`. Timers don't run inside widget tests unless you pump, so a delay would make tests hang.

---

### Step 8: SessionController, and the dashboard shows who you are

**Goal:**
- One app-wide object knows the current session.
- It is `null` when there is no user **or** the user has no group; both mean "needs onboarding" later.
- The dashboard title shows the active group and your role.

**Files:**
- new `test/core/session/session_controller_test.dart`
- new `lib/core/session/session_controller.dart`
- new `test/dashboard/dashboard_page_test.dart`
- edit `lib/app/app_dependencies.dart`
- edit `test/support/test_app.dart`
- edit `lib/routing/app_router.dart`
- edit `lib/dashboard/dashboard_page.dart`
- edit `lib/main.dart`

**Tests first.** `test/core/session/session_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/core/session/session_controller.dart';
import 'package:home_hub_client/demo/in_memory_group_repository.dart';
import 'package:home_hub_client/demo/in_memory_user_repository.dart';

void main() {
  test('has no session before restore', () {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(),
    );

    expect(controller.session, isNull);
  });

  test('restore builds a session in the first group', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(),
    );

    await controller.restore();

    final session = controller.requireSession;
    expect(session.user.displayName, 'Asha');
    expect(session.group.name, 'Sharma Family');
    expect(session.role, GroupRole.admin);
    expect(session.memberships, hasLength(2));
  });

  test('restore notifies listeners once', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(),
    );
    var calls = 0;
    controller.addListener(() => calls++);

    await controller.restore();

    expect(calls, 1);
  });

  test('no session when nobody is signed in', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(signedIn: null),
      groups: InMemoryGroupRepository(),
    );

    await controller.restore();

    expect(controller.session, isNull);
  });

  test('no session when the user has no group yet', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(memberships: const []),
    );

    await controller.restore();

    expect(controller.session, isNull);
    expect(() => controller.requireSession, throwsStateError);
  });
}
```

`test/dashboard/dashboard_page_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/demo/demo_data.dart';

import '../support/test_app.dart';

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
}
```

**See it fail:** `flutter test test/core/session test/dashboard`.

**Make it pass.**

`lib/core/session/session_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../models/group.dart';
import '../models/session.dart';
import '../repositories/group_repository.dart';
import '../repositories/user_repository.dart';

/// App-wide "who am I, and in which group".
///
/// A [ChangeNotifier] so that, once onboarding exists, the router can listen
/// to it and redirect when the user signs in or out.
class SessionController extends ChangeNotifier {
  SessionController({required this._users, required this._groups});

  final UserRepository _users;
  final GroupRepository _groups;

  Session? _session;

  /// The current session, or null when nobody is signed in or the user has
  /// no group yet (both mean "needs onboarding").
  Session? get session => _session;

  /// The current session, for pages that are only reachable with one.
  Session get requireSession =>
      _session ??
      (throw StateError('No session: this page needs a user with a group'));

  /// Loads the signed-in user and their groups; the first group is active.
  Future<void> restore() async {
    final user = await _users.currentUser();
    final memberships = user == null
        ? const <Membership>[]
        : await _groups.membershipsOf(user.id);
    _session = (user == null || memberships.isEmpty)
        ? null
        : Session(
            user: user,
            memberships: memberships,
            active: memberships.first,
          );
    notifyListeners();
  }
}
```

`lib/app/app_dependencies.dart` (now with a `demo()` startup recipe):

```dart
import '../api/api_client.dart';
import '../core/session/session_controller.dart';
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
    );
  }

  final ApiClient api;
  final FeatureRegistry features;
  final SessionController session;
}
```

In `test/support/test_app.dart`:
1. Add these imports:

```dart
import 'package:home_hub_client/core/models/user.dart';
import 'package:home_hub_client/core/session/session_controller.dart';
import 'package:home_hub_client/demo/demo_data.dart';
import 'package:home_hub_client/demo/in_memory_group_repository.dart';
import 'package:home_hub_client/demo/in_memory_user_repository.dart';
```

2. Replace `testDependencies` with:

```dart
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
  );
}
```

In `lib/routing/app_router.dart`, change the `/home` builder to:

```dart
        builder: (context, state) =>
            DashboardPage(session: deps.session.requireSession),
```

`lib/dashboard/dashboard_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../core/models/session.dart';

/// The home dashboard at `/home`.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(session.group.name),
            Text(
              '${session.user.displayName} · ${session.role.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: const Center(child: Text('Dashboard')),
    );
  }
}
```

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'config.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  // Required before doing async work ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final deps = await AppDependencies.demo(
    api: ApiClient(baseUrl: AppConfig.apiBaseUrl),
  );
  runApp(HomeHubApp(router: createRouter(deps: deps)));
}
```

**Concepts:**
- `ChangeNotifier` keeps a list of listeners, and `notifyListeners()` calls them. Today only the test listens; later the router will.
- `?? (throw ...)` means "use the left side, or else throw".
- Dart *promotes* `user` to non-null after the `user == null ||` check, so `Session(user: user, ...)` compiles.
- `restore()` is awaited before `runApp`, so every route has a session from the first frame.

---

### Step 9: per-user, per-group dashboard storage

**Goal:** a repository that remembers which tiles a user pinned **in a given group**.

**Files:**
- new `test/demo/in_memory_dashboard_repository_test.dart`
- new `lib/dashboard/dashboard_repository.dart`
- new `lib/demo/in_memory_dashboard_repository.dart`

**Test first:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/demo/in_memory_dashboard_repository.dart';

void main() {
  test('nothing is saved at first', () async {
    final repo = InMemoryDashboardRepository();

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      isNull,
    );
  });

  test('save then load returns the same ids in order', () async {
    final repo = InMemoryDashboardRepository();

    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ['files', 'notes'],
    );

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      ['files', 'notes'],
    );
  });

  test('layouts are separate per user and per group', () async {
    final repo = InMemoryDashboardRepository();

    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ['vault'],
    );

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'book-club'),
      isNull,
    );
    expect(
      await repo.loadPinned(userId: 'u-ravi', groupCode: 'sharma-family'),
      isNull,
    );
  });

  test('callers cannot change what is stored', () async {
    final repo = InMemoryDashboardRepository();
    final ids = ['notes'];
    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ids,
    );

    ids.add('changed-after-save');
    final loaded = await repo.loadPinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
    );
    loaded!.add('changed-after-load');

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      ['notes'],
    );
  });
}
```

**See it fail:** `flutter test test/demo/in_memory_dashboard_repository_test.dart`.

**Make it pass.**

`lib/dashboard/dashboard_repository.dart`:

```dart
/// Stores each user's personal dashboard layout, separately in every group.
abstract interface class DashboardRepository {
  /// Pinned feature ids, in display order, or null if [userId] never
  /// customised their dashboard in group [groupCode].
  Future<List<String>?> loadPinned({
    required String userId,
    required String groupCode,
  });

  Future<void> savePinned({
    required String userId,
    required String groupCode,
    required List<String> featureIds,
  });
}
```

`lib/demo/in_memory_dashboard_repository.dart`:

```dart
import '../dashboard/dashboard_repository.dart';

/// [DashboardRepository] kept in memory; forgets everything on restart.
class InMemoryDashboardRepository implements DashboardRepository {
  // Keyed by the record (userId, groupCode).
  final _pinned = <(String, String), List<String>>{};

  @override
  Future<List<String>?> loadPinned({
    required String userId,
    required String groupCode,
  }) async {
    final saved = _pinned[(userId, groupCode)];
    return saved == null ? null : List.of(saved);
  }

  @override
  Future<void> savePinned({
    required String userId,
    required String groupCode,
    required List<String> featureIds,
  }) async {
    _pinned[(userId, groupCode)] = List.of(featureIds);
  }
}
```

**Concepts:**
- `List.of(...)` makes a copy, so nobody outside can change the stored list.
- `null` here means "never customised", which is different from "customised to an empty list".

---

### Step 10: DashboardViewModel

**Goal:** all dashboard logic in one plain, unit-testable class:
- defaults when nothing is saved
- unknown saved ids dropped
- pinning appends and saves

**Files:**
- new `test/dashboard/dashboard_view_model_test.dart`
- new `lib/dashboard/dashboard_view_model.dart`

**Test first:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/core/models/session.dart';
import 'package:home_hub_client/core/models/user.dart';
import 'package:home_hub_client/dashboard/dashboard_view_model.dart';
import 'package:home_hub_client/demo/demo_data.dart';
import 'package:home_hub_client/demo/in_memory_dashboard_repository.dart';
import 'package:home_hub_client/features/all_features.dart';
import 'package:home_hub_client/features/feature_module.dart';

Session _sessionFor(User user, Group group) {
  final memberships = DemoData.memberships
      .where((m) => m.userId == user.id)
      .toList();
  return Session(
    user: user,
    memberships: memberships,
    active: memberships.firstWhere((m) => m.group.code == group.code),
  );
}

DashboardViewModel _viewModel(
  InMemoryDashboardRepository repo, {
  Group group = DemoData.sharmaFamily,
}) => DashboardViewModel(
  session: _sessionFor(DemoData.asha, group),
  features: buildFeatureRegistry(),
  repository: repo,
);

List<String> _ids(List<FeatureModule> modules) => [
  for (final m in modules) m.id,
];

void main() {
  test('is loading until load completes', () async {
    final vm = _viewModel(InMemoryDashboardRepository());

    expect(vm.isLoading, isTrue);
    await vm.load();
    expect(vm.isLoading, isFalse);
  });

  test('uses the default tiles when nothing is saved', () async {
    final vm = _viewModel(InMemoryDashboardRepository());

    await vm.load();

    expect(_ids(vm.pinned), ['notes', 'reminders']);
    expect(_ids(vm.addable), ['vault', 'pictures', 'files']);
  });

  test('uses the saved order and drops unknown ids', () async {
    final repo = InMemoryDashboardRepository();
    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ['files', 'old-thing', 'notes'],
    );
    final vm = _viewModel(repo);

    await vm.load();

    expect(_ids(vm.pinned), ['files', 'notes']);
  });

  test('pin appends, notifies and saves', () async {
    final repo = InMemoryDashboardRepository();
    final vm = _viewModel(repo);
    await vm.load();
    var calls = 0;
    vm.addListener(() => calls++);

    await vm.pin('vault');

    expect(_ids(vm.pinned), ['notes', 'reminders', 'vault']);
    expect(_ids(vm.addable), ['pictures', 'files']);
    expect(calls, 1);
    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      ['notes', 'reminders', 'vault'],
    );
  });

  test('pin ignores already-pinned and unknown ids', () async {
    final repo = InMemoryDashboardRepository();
    final vm = _viewModel(repo);
    await vm.load();
    var calls = 0;
    vm.addListener(() => calls++);

    await vm.pin('notes');
    await vm.pin('nope');

    expect(calls, 0);
    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      isNull,
    );
  });

  test('pinning in one group does not change another group', () async {
    final repo = InMemoryDashboardRepository();
    final family = _viewModel(repo);
    await family.load();
    await family.pin('vault');

    final club = _viewModel(repo, group: DemoData.bookClub);
    await club.load();

    expect(_ids(club.pinned), ['notes', 'reminders']);
  });

  test('exposes group name and user label', () {
    final vm = _viewModel(InMemoryDashboardRepository());

    expect(vm.groupName, 'Sharma Family');
    expect(vm.userLabel, 'Asha · Admin');
  });
}
```

**See it fail:** `flutter test test/dashboard/dashboard_view_model_test.dart`.

**Make it pass.** `lib/dashboard/dashboard_view_model.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../core/models/session.dart';
import '../features/feature_module.dart';
import '../features/feature_registry.dart';
import 'dashboard_repository.dart';

/// State and actions for the dashboard page: which tiles are pinned, which
/// can still be added, and pinning a new one.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required this._session,
    required this._features,
    required this._repository,
  });

  final Session _session;
  final FeatureRegistry _features;
  final DashboardRepository _repository;

  bool _isLoading = true;
  List<FeatureModule> _pinned = const [];
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String get groupName => _session.group.name;
  String get userLabel =>
      '${_session.user.displayName} · ${_session.role.label}';

  /// Tiles on the dashboard, in the user's order.
  List<FeatureModule> get pinned => _pinned;

  /// Modules the '+' tile can still add.
  List<FeatureModule> get addable => [
    for (final module in _features.all)
      if (!_isPinned(module.id)) module,
  ];

  /// Loads this user's layout for the active group, or the defaults.
  Future<void> load() async {
    final saved = await _repository.loadPinned(
      userId: _session.user.id,
      groupCode: _session.group.code,
    );
    final modules = <FeatureModule>[];
    for (final id in saved ?? _features.defaultPinnedIds) {
      // Skip ids the app no longer has (e.g. a removed module).
      final module = _features.byId(id);
      if (module != null) modules.add(module);
    }
    _pinned = modules;
    _isLoading = false;
    _notify();
  }

  /// Adds [featureId] to the end of the dashboard and saves the layout.
  Future<void> pin(String featureId) async {
    final module = _features.byId(featureId);
    if (module == null || _isPinned(featureId)) return;
    _pinned = [..._pinned, module];
    _notify(); // update the screen first, then save
    await _repository.savePinned(
      userId: _session.user.id,
      groupCode: _session.group.code,
      featureIds: [for (final m in _pinned) m.id],
    );
  }

  bool _isPinned(String id) => _pinned.any((m) => m.id == id);

  // load() is async: if the page closes before it finishes, notifying a
  // disposed ChangeNotifier would throw.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
```

**Concepts:**
- A **view model** holds page logic and never imports widgets or go_router, which is why it is tested with plain `test()`.
- `[..._pinned, module]` makes a *new* list with one more item (the spread operator).
- We compare modules **by id**, not by object identity.

---

### Step 11: the real dashboard (tiles, navigation, **+** picker)

**Goal:**
- a grid of pinned tiles
- tapping a tile goes to the feature
- **+** opens a bottom sheet of addable modules
- **+** disappears when everything is pinned
- the cloud icon opens server status

**Files:**
- edit `test/dashboard/dashboard_page_test.dart`
- edit `lib/dashboard/dashboard_page.dart`
- new `lib/dashboard/widgets/feature_tile.dart`
- new `lib/dashboard/widgets/add_feature_tile.dart`
- edit `lib/app/app_dependencies.dart`
- edit `test/support/test_app.dart`
- edit `lib/routing/app_router.dart`

**Tests first.** Replace `test/dashboard/dashboard_page_test.dart` with:

```dart
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
```

**See it fail:** `flutter test test/dashboard/dashboard_page_test.dart`. `addTileKey` and `tileKey` are undefined.

**Make it pass.**

`lib/dashboard/widgets/feature_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../features/feature_module.dart';

/// A dashboard tile that opens one feature module.
class FeatureTile extends StatelessWidget {
  const FeatureTile({super.key, required this.module, required this.onTap});

  final FeatureModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module.icon, size: 40),
            const SizedBox(height: 8),
            Text(module.title),
          ],
        ),
      ),
    );
  }
}
```

`lib/dashboard/widgets/add_feature_tile.dart`:

```dart
import 'package:flutter/material.dart';

/// The '+' tile that lets the user add a module to their dashboard.
class AddFeatureTile extends StatelessWidget {
  const AddFeatureTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40),
            SizedBox(height: 8),
            Text('Add widget'),
          ],
        ),
      ),
    );
  }
}
```

`lib/dashboard/dashboard_page.dart` (replace the whole file):

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/models/session.dart';
import '../features/feature_registry.dart';
import '../routing/app_routes.dart';
import 'dashboard_repository.dart';
import 'dashboard_view_model.dart';
import 'widgets/add_feature_tile.dart';
import 'widgets/feature_tile.dart';

/// The home dashboard at `/home`: the user's pinned feature tiles plus '+'.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.session,
    required this.features,
    required this.repository,
  });

  static const addTileKey = ValueKey('dashboard-add-tile');
  static ValueKey<String> tileKey(String featureId) =>
      ValueKey('dashboard-tile-$featureId');

  final Session session;
  final FeatureRegistry features;
  final DashboardRepository repository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Created once in initState, not in build or in the route builder,
  // so navigating around does not replace it with a fresh, unloaded one.
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(
      session: widget.session,
      features: widget.features,
      repository: widget.repository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    // A bottom sheet is a temporary overlay, not a page with a URL,
    // so closing it with Navigator.pop is correct alongside go_router.
    final featureId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final module in _viewModel.addable)
              ListTile(
                leading: Icon(module.icon),
                title: Text(module.title),
                onTap: () => Navigator.of(sheetContext).pop(module.id),
              ),
          ],
        ),
      ),
    );
    if (featureId != null) await _viewModel.pin(featureId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_viewModel.groupName),
              Text(
                _viewModel.userLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Server status',
              icon: const Icon(Icons.cloud_outlined),
              onPressed: () => context.go(AppRoutes.status),
            ),
          ],
        ),
        body: _viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.extent(
                maxCrossAxisExtent: 220,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  for (final module in _viewModel.pinned)
                    FeatureTile(
                      key: DashboardPage.tileKey(module.id),
                      module: module,
                      onTap: () => context.go(AppRoutes.feature(module.id)),
                    ),
                  if (_viewModel.addable.isNotEmpty)
                    AddFeatureTile(
                      key: DashboardPage.addTileKey,
                      onTap: _openPicker,
                    ),
                ],
              ),
      ),
    );
  }
}
```

`lib/app/app_dependencies.dart` gains the dashboard repository:
1. Add these imports:

```dart
import '../dashboard/dashboard_repository.dart';
import '../demo/in_memory_dashboard_repository.dart';
```

2. Add `required this.dashboardRepository,` to the constructor.
3. Add the field `final DashboardRepository dashboardRepository;`.
4. In `demo()`, pass `dashboardRepository: InMemoryDashboardRepository(),`.

In `test/support/test_app.dart`:
1. Add `import 'package:home_hub_client/demo/in_memory_dashboard_repository.dart';`.
2. Pass `dashboardRepository: InMemoryDashboardRepository(),` in `testDependencies`.

In `lib/routing/app_router.dart`, the `/home` builder becomes:

```dart
        builder: (context, state) => DashboardPage(
          session: deps.session.requireSession,
          features: deps.features,
          repository: deps.dashboardRepository,
        ),
```

Run `flutter test`. Everything is green: about 57 tests in a few seconds (`flutter test` prints `+57: All tests passed!`).

**Concepts:**
- **Why is the view model in `State` and not in the route builder?** go_router calls route builders again while navigating, for example on the way to `/home/features/notes`. A view model created there would be replaced by a fresh, empty one. The `State` object survives those rebuilds, so `initState` runs once.
- `ListenableBuilder` redraws whenever the view model calls `notifyListeners()`.
- `ValueKey` gives a widget a stable name that tests can find.
- `GridView.extent` fits as many ~220 px tiles per row as the screen allows, so the same layout works on phone and web.
- `late final` means "assigned exactly once, a bit later" (in `initState`).

---

### Step 12: clean URLs in `main.dart`

**Goal:** `/home/features/notes` instead of `/#/home/features/notes` on web. No test is possible here; this is wiring only, so it is checked manually in section 5.

In `lib/main.dart`:
1. Add `import 'package:flutter_web_plugins/url_strategy.dart';`.
2. Call `usePathUrlStrategy();` right after `WidgetsFlutterBinding.ensureInitialized();`.

The final file:

```dart
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
```

Run `dart format . && flutter analyze && flutter test`.

---

## 5. Web deployment (needed for deep links)

With path URLs, the browser asks nginx for `/home/features/notes`. That file doesn't exist, so stock nginx answers **404**. The fix is to send any path that isn't a real file to `index.html`; the app then reads the URL and routes.

**New file `client/nginx.conf`:**

```nginx
server {
    # Both stacks: inside the container `localhost` resolves to ::1 first,
    # which the compose healthcheck (wget http://localhost/) relies on.
    listen 80;
    listen [::]:80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Flutter web file names (main.dart.js, flutter_bootstrap.js, ...) carry
    # no content hash, so make browsers revalidate everything; nginx's ETags
    # keep that cheap. This is what lets a new deployment be picked up.
    add_header Cache-Control "no-cache";

    # Optional hardening: a missing static asset (a mistyped image path, or a
    # stale main.dart.js chunk after a deploy) gets a real 404 instead of
    # index.html, so Flutter does not report confusing decode errors.
    # App routes have no file extension, so they still fall through to
    # index.html below.
    location ~* \.(?:js|mjs|wasm|json|png|jpg|jpeg|gif|svg|ico|ttf|otf|woff2?|css|map)$ {
        try_files $uri =404;
    }

    # Single-page app: serve the file if it exists, otherwise hand the URL
    # to the Flutter app (go_router decides what to show, incl. its 404 page).
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**`client/Dockerfile`, stage 2.** Add one line:

```dockerfile
# Stage 2: serve the static bundle.
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/build/web /usr/share/nginx/html
```

`web/index.html` already has `<base href="$FLUTTER_BASE_HREF">`, which defaults to `/`, so leave it alone unless you ever host under a sub-path. `API_BASE_URL` still comes from the Dockerfile's `ARG` default. Compose passes no build args today; add `build: { context: ./client, args: { API_BASE_URL: ... } }` if you need to override it. nginx.conf has no environment-specific values.

**Manual check:**

```sh
cd /Users/ysharma/home_hub
docker compose up --build -d web_client     # the build runs flutter test first; red tests stop it
docker compose ps                           # repeat until web_client shows "healthy"
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/home/features/notes   # expect 200
```

- `-d` runs the containers in the background. Without it, `up` stays attached and streams logs, so you would never reach the `curl` line. Pressing Ctrl-C there would also stop the containers.
- Instead of `docker compose ps`, you can watch the startup with `docker compose logs -f web_client`. Ctrl-C there only stops following the logs; the containers keep running.
- This also starts `db`, `migrate` and `server`, because `web_client` has `depends_on: server: service_healthy`. That is expected.

Then, in a browser:
1. Open `http://localhost:8080/home/features/notes` directly. The Notes page shows.
2. Press refresh. The page still shows.
3. Press browser Back. You land on the dashboard.
4. Open `http://localhost:8080/`. It goes to `/home`.
5. Open `http://localhost:8080/nope`. The app's "Page not found" appears, not nginx's. nginx returns status 200 with index.html for app paths; that is normal for single-page apps.

When you are done, stop everything with `docker compose down`.

---

## 6. How to extend later

### 6.1 Add a feature module
1. Write a test first. The router test's `for` loop already covers "reachable at its URL". Add one assertion to the registry test's id list.
2. Create `lib/features/<id>/<id>_module.dart` exporting a `FeatureModule` with a lowercase id.
3. Add it to `buildFeatureRegistry()`.

The route, dashboard tile and **+** entry follow automatically. Never rename an id later: it is both the URL and the saved-layout key.

To give a module its own sub-pages, for example a note detail at `/home/features/notes/abc`, write the router test first ("shows 'Note abc'; back returns to notes; back again to dashboard"). Then:

```dart
final notesModule = FeatureModule(
  id: 'notes',
  title: 'Notes',
  icon: Icons.sticky_note_2_outlined,
  pinnedByDefault: true,
  pageBuilder: (context, state) => const NotesPage(),
  routes: [
    GoRoute(
      path: ':noteId', // relative: /home/features/notes/<noteId>
      builder: (context, state) =>
          NoteDetailPage(noteId: state.pathParameters['noteId']!),
    ),
  ],
);
```

`app_router.dart` does not change. Put ids in the path, and never pass objects through `extra`, because they are lost on a web refresh.

### 6.2 Add onboarding and an auth redirect
1. **Add the paths first.** Add `static const welcome = '/welcome';` and `static const signup = '/signup';` to `AppRoutes`, with a test in `app_routes_test.dart`. The next step uses them, so it would not compile without them.
2. **Pure function next, unit-tested with no widgets** (`lib/routing/app_redirect.dart`):

```dart
import '../core/models/session.dart';
import 'app_routes.dart';

const _publicPaths = {AppRoutes.welcome, AppRoutes.signup};

/// Where to send the user instead, or null to allow the navigation.
String? appRedirect({required Session? session, required Uri uri}) {
  final isPublic = _publicPaths.contains(uri.path);
  if (session == null) {
    return isPublic
        ? null
        : Uri(
            path: AppRoutes.welcome,
            queryParameters: {'from': uri.toString()},
          ).toString();
  }
  return isPublic ? (_safeFrom(uri) ?? AppRoutes.home) : null;
}

/// Accepts only in-app, non-public paths, so `?from=https://evil.example`
/// cannot send users off-site and `?from=/welcome` cannot loop.
String? _safeFrom(Uri uri) {
  final from = uri.queryParameters['from'];
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  // tryParse, not parse: a malformed value such as `/%zz` must not throw
  // inside the redirect.
  final parsed = Uri.tryParse(from);
  if (parsed == null || _publicPaths.contains(parsed.path)) return null;
  return from;
}
```

   Tests to write:
   - signed out on `/home/features/notes` gives `/welcome?from=...`
   - signed out on `/welcome` gives `null`
   - signed in on `/welcome?from=/home/features/notes` gives that path
   - signed in with `from=https://evil.example` or `from=/welcome` gives `/home`
   - signed in with `from=/%zz` gives `/home`
   - signed in on `/home` gives `null`

3. **Wire it in** `createRouter`, adding two lines to `GoRouter(...)`:

```dart
    refreshListenable: deps.session, // re-run redirect when the session changes
    redirect: (context, state) =>
        appRedirect(session: deps.session.session, uri: state.uri),
```

4. Add top-level `GoRoute`s for `AppRoutes.welcome` and `AppRoutes.signup`, as siblings of `/home`, not children. Optionally point `/` at the welcome page instead of redirecting.
5. Add `signIn(...)`/`signOut()` to `SessionController`, implemented through new `UserRepository` methods. Pages call the controller and never `InMemory...` classes directly.
6. When "signed in but no group yet" needs its own page (`/groups/new`), replace `Session?` with a small `sealed class SessionState` (`SignedOut`, `NeedsGroup(user)`, `Active(session)`) and `switch` over it in `appRedirect`. The compiler then makes sure every case is handled.
7. When a real server makes `restore()` slow, stop awaiting it in `main()`. Add a `/loading` route and treat "restoring" as a session state.
8. Group switching: add `SessionController.switchGroup(code)`. In the `/home` builder, pass `key: ValueKey(session.group.code)` to `DashboardPage`, so a new group creates a fresh view model and loads that group's layout.

### 6.3 Swap fake repositories for server-backed ones
1. Add an `ApiUserRepository implements UserRepository` (and the group and dashboard equivalents) that call new methods on `ApiClient`. Test them with `MockClient`, as the status page tests do.
2. Add `AppDependencies.live({required ApiClient api})`, which builds the same objects with the API repositories.
3. Call `live` instead of `demo` in `main.dart`.

Pages, view models and their tests do not change. `DemoData` and the in-memory classes stay for tests and local demos, and they are never reachable from `live()`.

### 6.4 Admin/Member permission checks
- The model is already there: `session.isAdmin` and `membership.role`.
- For a module that only some roles see, add an optional field `final bool Function(Session session) isAvailableTo;` to `FeatureModule`, defaulting to "everyone". Filter `pinned` and `addable` in the view model with it, test-first.
- To also block the URL, the feature's `GoRoute` needs a `redirect`. Feature routes are generated from `FeatureModule` in `app_router.dart`, and `FeatureModule` has no redirect field yet, so this is a one-time change to the router. Write a router test first (for example "a member opening an admin-only module lands on `/home`"). Then pick one of these:
  - Add `final GoRouterRedirect? redirect;` to `FeatureModule` (default `null`), and pass `redirect: module.redirect` in the `for (final module in deps.features.all) GoRoute(...)` loop. Each module can then supply its own redirect.
  - Or reuse `isAvailableTo` in that loop: `redirect: (context, state) => module.isAvailableTo(deps.session.requireSession) ? null : AppRoutes.home`.

  After that one change, modules control access without editing the router again.
- Per the README, only *sensitive Vault items* are admin-only. Vault itself likely stays visible and checks `isAdmin` inside its own pages.
- **Hiding things in the client is UX, not security.** The server must enforce group and role access.
- Don't put "encrypted" or "E2E" in Vault copy until it is built.

### 6.5 When to add more tools
| Trigger | Add |
|---|---|
| Passing dependencies through many widget levels gets painful | `provider ^6.1.5+1`: wrap `HomeHubApp` in `MultiProvider` with the `AppDependencies` fields |
| Persistent navigation chrome (nav rail or bottom bar) around feature pages | Wrap the `/home` children in a `ShellRoute`. URLs stay the same. |
| Many routes with typed parameters | `go_router_builder` + `build_runner` |
| Models with many fields or JSON | `freezed` / `json_serializable` |

### 6.6 Later: Flutter 3.47 + go_router 18 (one dedicated change)
1. Bump `FLUTTER_VERSION` in the Dockerfile to 3.47.x, and your local SDK to match.
2. Run `flutter pub add material_ui cupertino_ui` and set `go_router: ^18.1.3`.
3. Run `dart fix --apply --code=migrate_design_widgets`, then `flutter analyze && flutter test`.

Never mix `package:flutter/material.dart` and `material_ui` imports: their types don't match each other. The test suite from this guide is your safety net.

---

## 7. Definition of done

- [ ] `flutter --version` (or the Docker alias) reports Flutter 3.44.0.
- [ ] `pubspec.yaml` has `go_router: ^17.5.0` and `flutter_web_plugins: sdk: flutter`, and `pubspec.lock` is regenerated with `flutter pub get`.
- [ ] `test/widget_test.dart` and `MainApp` are gone. `ServerStatusPage` lives in `lib/server_status/` with its 2 tests in `test/server_status/`.
- [ ] Each of steps 1–11 was done red first, then green.
- [ ] `dart format .` changes nothing.
- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes (about 57 tests, no network; it prints `+57: All tests passed!`).
- [ ] `/` goes to `/home`, which shows the active group, your name and role, the default tiles (Notes, Reminders) and **+**.
- [ ] Every module opens at `/home/features/<id>`, and back returns to the dashboard.
- [ ] `/home/features`, `/home/features/nope`, `/home/features/Notes` and `/xyz` show "Page not found" with "Back to home".
- [ ] **+** adds a module, the tile appears, and **+** hides when all modules are pinned. Layouts are separate per user and per group (view model test).
- [ ] The cloud icon opens `/home/status`, and back returns to the dashboard.
- [ ] Only `app/app_dependencies.dart` and `test/` import from `lib/demo/`.
- [ ] No placeholder copy claims encryption or security.
- [ ] `client/nginx.conf` exists and the Dockerfile copies it. `docker compose up --build -d web_client` succeeds and `docker compose ps` shows web_client healthy. `curl` on `/home/features/notes` gives 200, and a browser refresh on a deep link works. `docker compose down` stops everything afterwards.
- [ ] Changes are left uncommitted for you to review and commit yourself.
