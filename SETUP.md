# Simple Coaching Board - Multi-Platform Setup Guide

This document covers setup and configuration for developing the Simple Coaching Board app across **Web**, **iOS**, and **Android** platforms.

---

## Prerequisites

### Required Tools
- **Flutter SDK**: 3.12.0 or later
- **Dart SDK**: Included with Flutter
- **Git**: For version control
- **Node.js & npm**: For web development

### Platform-Specific Requirements

#### macOS (for iOS and Android on Mac)
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install CocoaPods (for iOS dependencies)
sudo gem install cocoapods

# Install Android SDK (via Android Studio)
# Download from: https://developer.android.com/studio
```

#### Windows/Linux (for Android)
- Android Studio or Android SDK Command-line tools
- Java Development Kit (JDK) 17 or later

#### iOS Development (macOS only)
- Xcode 14.0 or later
- iOS deployment target: 12.0 or later
- Apple Developer Account (for device deployment)

---

## Project Setup

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone https://github.com/stevewaz/simple_coaching_board.git
cd simple_coaching_board

# Get Flutter packages
flutter pub get

# Get build_runner dependencies
flutter pub get --upgrade

# Generate code (Drift database)
flutter pub run build_runner build
```

### 2. Verify Flutter Setup

```bash
# Check Flutter/Dart environment
flutter doctor

# Expected output should show:
# ✓ Flutter (Channel stable, version 3.x.x)
# ✓ Dart (version 3.x.x)
# ✓ Android SDK (version)
# ✓ Xcode (for iOS)
```

---

## Platform-Specific Setup

### Web Configuration

#### Build Web Assets
```bash
# Enable web (if not already enabled)
flutter config --enable-web

# Build web version
flutter build web --release

# Output directory: build/web/
```

#### Running Web Development Server
```bash
# Development mode with hot reload
flutter run -d chrome

# Or specify another browser
flutter run -d edge    # Edge
flutter run -d firefox # Firefox
```

#### Web Deployment
The app is configured to deploy to **GitHub Pages**:

```bash
# Build optimized web version
flutter build web --release --web-renderer html

# Deploy (via GitHub Actions or manual)
# Artifacts deployed to: https://stevewaz.github.io/simple_coaching_board
```

#### Web-Specific Configuration
- **Entry point**: `web/index.html`
- **Manifest**: `web/manifest.json` (PWA configuration)
- **Assets**: 
  - `drift_worker.js` - Drift database worker
  - `sqlite3.wasm` - SQLite for web
- **Icons**: `web/icons/` directory

#### Service Workers & PWA
The web build supports Progressive Web App (PWA) features:
- Offline support via service workers
- App installation to home screen
- Cached assets for fast loading

---

### Android Configuration

#### SDK Configuration
```bash
# Check Android SDK setup
flutter doctor -v

# Required minimum: API 21 (Lollipop)
# Target: API 34+ (recommended)
```

#### Build Configuration
Location: `android/app/build.gradle.kts`

Current settings:
```kotlin
android {
    namespace = "com.example.simple_coaching_board"
    compileSdk = flutter.compileSdkVersion  // Currently 34+
    minSdk = flutter.minSdkVersion          // Currently 21
    targetSdk = flutter.targetSdkVersion    // Currently 34+
}
```

#### Build and Run
```bash
# List connected Android devices
flutter devices

# Run on Android device/emulator
flutter run -d <device-id>

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build Android App Bundle (for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Signing Configuration (Release Builds)
Before releasing to Google Play, configure signing:

1. Create keystore:
```bash
keytool -genkey -v -keystore ~/key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload-key
```

2. Create `android/local.properties`:
```properties
storeFile=/path/to/key.jks
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload-key
```

3. Update `android/app/build.gradle.kts`:
```kotlin
signingConfigs {
    release {
        keyAlias = System.getenv("KEY_ALIAS") ?: "upload-key"
        keyPassword = System.getenv("KEY_PASSWORD")
        storeFile = file(System.getenv("KEYSTORE_PATH") ?: "key.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD")
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

#### Gradle Configuration
- **Location**: `android/gradle.properties`
- **Java version**: JVM 17 (Kotlin + Java)
- **Build directory**: Shared `build/` directory at project root

---

### iOS Configuration

#### Development Requirements
- Xcode 14.0+ installed
- iOS 12.0+ deployment target
- CocoaPods for dependency management

#### Build Configuration
Location: `ios/Podfile` and `ios/Runner.xcodeproj`

#### Build and Run
```bash
# List connected iOS devices
flutter devices

# Run on iOS device/simulator
flutter run -d <device-id>

# Build IPA (debug)
flutter build ios --debug

# Build for release
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app
```

#### Building for App Store (Release)

1. Open Xcode workspace:
```bash
open ios/Runner.xcworkspace
```

2. Configure signing:
   - Select "Runner" project
   - Go to "Signing & Capabilities"
   - Select team and configure provisioning profiles
   - Update bundle identifier if needed

3. Build via Xcode or CLI:
```bash
flutter build ios --release
flutter build ipa --release
# Output: build/ios/ipa/simple_coaching_board.ipa
```

#### Code Signing
```bash
# Automatic signing (recommended for development)
# Set in Xcode: Automatically manage signing ✓

# Manual signing (for CI/CD)
# Use export options or certificates/provisioning profiles
```

#### Dependencies Management
```bash
# Update iOS pods (after adding dependencies)
cd ios
pod update
pod install
cd ..

# Clean iOS build (if issues)
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
```

---

## Development Workflow

### Hot Reload & Hot Restart
```bash
# Development run (with hot reload)
flutter run

# Hot reload (preserve app state)
# Press 'r' in terminal

# Hot restart (restart app, preserve breakpoints)
# Press 'R' in terminal

# Full restart
# Press 'q' to quit and run again
```

### Running Tests
```bash
# Run all unit/widget tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage

# View coverage
# Open coverage/lcov-report/index.html
```

### Code Generation
```bash
# Generate Drift database code
flutter pub run build_runner build

# Watch for changes (regenerate on save)
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

### Linting & Analysis
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Fix formatting issues
dart fix --apply
```

---

## Platform-Specific Development

### Web Development
- **Browser DevTools**: Open with F12 or right-click → Inspect
- **Flutter DevTools**: Run `flutter pub global activate devtools` then `devtools`
- **Hot Reload**: Changes reflect instantly in browser
- **Responsive Design**: Test at different breakpoints

### Android Development
- **Android Emulator**: Run via Android Studio or `flutter emulators --launch <emulator-id>`
- **Physical Device**: Enable USB Debugging in Developer Options
- **Logcat**: View logs with `flutter logs` or `adb logcat`

### iOS Development
- **Simulator**: Press `Cmd+Shift+H` to simulate home button
- **Device Deployment**: Requires Apple Developer Account
- **Console**: View logs with `flutter logs` or Xcode console
- **Profile**: Use Xcode Profiler for performance analysis

---

## Build Configurations

### Debug Build
```bash
flutter run
# Includes debugging symbols, assertions enabled, slower
```

### Release Build
```bash
flutter build web --release
flutter build apk --release
flutter build ipa --release
# Optimized for size/speed, no debug symbols, slower compilation
```

### Profile Build
```bash
flutter run --profile
# Optimized but with minimal profiling overhead, for performance testing
```

---

## Database Setup (Drift)

The app uses **Drift** for local SQLite persistence across all platforms.

### Initial Setup
```bash
# Generate database code
flutter pub run build_runner build

# This creates:
# - lib/database/database.g.dart (generated)
# - Database migration scripts
```

### Database Configuration
Location: `lib/database/database.dart`

Features:
- SQLite on all platforms (iOS, Android)
- IndexedDB on Web (via sqlite3.wasm)
- Type-safe queries
- Automatic migrations
- Reactive streams

### Database Debugging
```dart
// Enable logging in database initialization
import 'package:drift/native.dart';

// Add logStatements: true to NativeDatabase
final db = AppDatabase(
  NativeDatabase.memory(logStatements: true),
);
```

---

## Dependency Management

### Current Dependencies
```yaml
# Core
flutter: sdk (Material Design)
cupertino_icons: iOS style icons

# Database
drift: ^2.22.0          # SQLite ORM
drift_flutter: ^0.2.0   # Flutter integration
```

### Recommended Additional Dependencies

#### For Field Services Features
```yaml
# Location & Maps
google_maps_flutter: ^2.5.0
geolocator: ^11.0.0

# GPS Background Tracking
workmanager: ^0.5.0              # Background jobs
background_locator: ^1.9.1

# Real-time Communication
firebase_core: ^2.24.0
firebase_messaging: ^14.6.0
firebase_database: ^10.3.0
```

#### For Payments
```yaml
stripe_flutter: ^50.0.0
square_up_sdk: ^25.0.0
pay: ^2.5.0
```

#### For UI/UX
```yaml
provider: ^6.0.0                 # State management
get: ^4.6.5                      # Alternative state management
go_router: ^13.0.0               # Navigation
lottie: ^3.0.0                   # Animations
```

#### For Testing
```yaml
mockito: ^5.4.0
integration_test: ^0.9.0
```

---

## Environment Variables & Configuration

### Configuration by Platform

#### Web
- Set in environment during build:
```bash
flutter build web --dart-define=API_URL=https://api.example.com
```

#### Android
- Set in `android/local.properties`
- Access via platform channel

#### iOS
- Set in `ios/Runner.xcodeproj` build settings
- Access via platform channel

### Example: Adding Environment Variable
```dart
// In Dart
const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
```

---

## Troubleshooting

### Common Issues

#### "Flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### "Could not build the precompiled kernel"
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build
```

#### Android build fails
```bash
# Clean build
flutter clean
rm -rf android/.gradle
flutter pub get
flutter run
```

#### iOS build fails
```bash
# Clean pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

#### Web build size too large
```bash
# Use html renderer for smaller builds
flutter build web --release --web-renderer html

# Check build size
dart pub global activate source_gen_helper
pub run source_gen_helper
```

### Performance Issues
```bash
# Profile the app
flutter run --profile

# Analyze performance in DevTools
# Open DevTools: flutter pub global run devtools

# Check frame rendering
# Enable "Show frames" in DevTools Performance tab
```

---

## CI/CD Setup

### GitHub Actions
The project includes GitHub Actions workflow for:
- Running tests
- Building all platforms
- Deploying web to GitHub Pages

Location: `.github/workflows/`

Current workflows:
- `deploy-web.yml` - Builds and deploys web to GitHub Pages

### Testing CI/CD Locally
```bash
# Simulate CI environment
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  cirrusci/flutter:latest \
  flutter test
```

---

## Performance Optimization

### Web
- Use `--web-renderer html` for smaller builds
- Enable minification: `flutter build web --release`
- Use service workers for caching

### Android
- Use ProGuard/R8 for code shrinking
- Enable multidex for large apps
- Profile with `flutter run --profile`

### iOS
- Use release builds for benchmarking
- Enable App Thinning in Xcode
- Profile with Instruments in Xcode

---

## Deployment Checklist

### Before Release

#### All Platforms
- [ ] Run `flutter test`
- [ ] Run `flutter analyze`
- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Test on real devices
- [ ] Test offline functionality
- [ ] Check performance: `flutter run --profile`

#### Web
- [ ] Test on multiple browsers (Chrome, Safari, Firefox, Edge)
- [ ] Test responsive design (mobile, tablet, desktop)
- [ ] Check PWA features (offline, installation)
- [ ] Verify GitHub Pages deployment

#### Android
- [ ] Test on multiple API levels (minimum API 21)
- [ ] Test on different screen sizes
- [ ] Test on different device manufacturers
- [ ] Prepare for Google Play: verify app bundle builds
- [ ] Configure signing certificate

#### iOS
- [ ] Test on iPhone and iPad
- [ ] Test on multiple iOS versions (minimum iOS 12)
- [ ] Verify on real device (not just simulator)
- [ ] Configure Apple Developer provisioning profiles
- [ ] Prepare TestFlight build
- [ ] Configure App Store Connect metadata

---

## Useful Commands Reference

```bash
# Project Setup
flutter pub get                          # Get dependencies
flutter pub upgrade                      # Upgrade all packages
flutter pub outdated                     # Check for updates

# Development
flutter run                              # Run with hot reload
flutter run --release                    # Run release build
flutter run --profile                    # Run with profiling
flutter run -d <device>                  # Run on specific device
flutter devices                          # List available devices

# Testing
flutter test                             # Run all tests
flutter test test/file_test.dart        # Run specific test
flutter test --coverage                  # Generate coverage report

# Building
flutter build web --release              # Build web
flutter build apk --release              # Build Android APK
flutter build appbundle --release        # Build Android App Bundle
flutter build ipa --release              # Build iOS

# Code Generation
flutter pub run build_runner build       # Generate code
flutter pub run build_runner watch       # Watch & regenerate
flutter pub run build_runner clean       # Clean generated files

# Analysis
flutter analyze                          # Analyze code
dart format lib/                         # Format code
dart fix --apply                         # Fix issues

# Cleaning
flutter clean                            # Clean build
flutter pub cache clean                  # Clear pub cache
```

---

## Resources

### Official Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Web](https://flutter.dev/web)
- [Flutter iOS](https://flutter.dev/docs/deployment/ios)
- [Flutter Android](https://flutter.dev/docs/deployment/android)

### Package Documentation
- [Drift/Moor](https://drift.simonbinder.eu/)
- [Provider](https://pub.dev/packages/provider)
- [Go Router](https://pub.dev/packages/go_router)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Subreddit](https://www.reddit.com/r/Flutter/)

---

## Next Steps

1. **Run the app**: `flutter run`
2. **Check device support**: `flutter doctor`
3. **Generate database code**: `flutter pub run build_runner build`
4. **Explore the codebase**: Start with `lib/main.dart`
5. **Run tests**: `flutter test`
6. **Read platform-specific docs** above for detailed setup
