# Memotage

Memotage is an offline-first, Material Design 3 digital scrapbook. It captures photos and processes them into custom postage stamps, complete with geocoding, unique identification, and local storage.

## Features

- **Stylized Captures:** Converts standard camera photos into digital postage stamps with custom borders and drop shadows.
- **Location Tagging:** Uses reverse-geocoding to translate GPS coordinates into readable location names.
- **Unique IDs:** Generates cryptographically unique identifiers (UUIDs) for each memory.
- **Material Design 3:** Built using Google's latest UX principles, featuring modern NavigationBars and SnackBars.
- **Native Sharing:** Captures the stylized UI via `RepaintBoundary` for seamless sharing of the formatted digital stamp.
- **Privacy-First:** Fully offline architecture. All images and metadata are processed and stored locally on your device.

## Installation

```bash
git clone https://github.com/yourusername/memotage.git
cd memotage
flutter pub get
flutter build apk
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

### iOS Build Note
While the Flutter codebase is cross-platform, building for iOS requires transferring the project to a macOS environment with Xcode installed.

## Tech Stack
- Flutter (Dart)
- `camera` for capturing media
- `geolocator` and `geocoding` for location tagging
- Background isolates for non-blocking image processing

## License

This project is licensed under the MIT License.
