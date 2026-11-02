# Stage 1: build the Flutter web bundle.
ARG FLUTTER_VERSION=3.44.0
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build

WORKDIR /src

# Resolve dependencies first so this layer is cached across source changes.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://server.home.hub:8000
RUN flutter test \
 && flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Stage 2: serve the static bundle.
FROM nginx:alpine
COPY --from=build /src/build/web /usr/share/nginx/html
