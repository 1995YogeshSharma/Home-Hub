# home_hub_client

Flutter client (web, Android, iOS) for the home hub server.

The server URL is set at build time (default `http://server.home.hub:8000`):

```sh
# Web, via Docker (runs tests, then serves on http://localhost:8080)
docker build -t home-hub-client .
docker build --build-arg API_BASE_URL=http://other.host:8000 -t home-hub-client .
docker run -p 8080:80 home-hub-client

# Mobile (needs a local Flutter SDK + Android SDK / Xcode)
flutter run --dart-define=API_BASE_URL=http://server.home.hub:8000
flutter build apk --dart-define=API_BASE_URL=http://server.home.hub:8000
```

Layout: `lib/config.dart` (build-time config), `lib/api/` (server API client), `lib/main.dart` (UI).
