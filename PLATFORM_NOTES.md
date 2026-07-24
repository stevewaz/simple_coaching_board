# Platform-Specific Development Notes

## Web Platform

### Key Differences
- No native code required
- Runs in browser using Dart-to-JavaScript compilation
- Database uses IndexedDB via sqlite3.wasm
- Location services via browser Geolocation API

### Web-Specific Configuration
```html
<!-- web/index.html -->
- Service worker support
- PWA manifest configuration
- Drift worker script (drift_worker.js)
- SQLite WASM module (sqlite3.wasm)
```

### Browser Support
| Browser | Support | Notes |
|---------|---------|-------|
| Chrome  | ✅ Full | Best performance |
| Safari  | ✅ Full | iOS 12+ required |
| Firefox | ✅ Full | Full support |
| Edge    | ✅ Full | Chromium-based |

### Development Tips
- Use Chrome DevTools for debugging (F12)
- Hot reload works in the browser
- Test responsive design with DevTools device emulation
- Check console for errors (Ctrl+Shift+J)

### Performance Considerations
- First load: ~2-3MB (with Flutter engine)
- Subsequent loads: Cached by service worker
- Use `--web-renderer html` for smaller bundle size
- Monitor network tab for unused assets

### Debugging
```bash
# Enable verbose logging
flutter run -v

# Enable DevTools
flutter pub global run devtools
# Access at http://localhost:9100
```

---

## Android Platform

### Key Differences
- Requires Android SDK and emulator/device
- Uses Kotlin for interop with native Android
- File system access via Dart plugins
- Background execution via WorkManager

### Minimum Requirements
- **Min SDK**: API 21 (Android 5.0 Lollipop)
- **Target SDK**: API 34+ (Android 14+)
- **Java Version**: JVM 17

### Android-Specific Configuration
```kotlin
// android/app/build.gradle.kts
- Namespace: com.example.simple_coaching_board
- Application ID (change before release)
- Signing configuration for release builds
- Gradle build optimization
```

### Running on Emulator
```bash
# Start emulator
flutter emulators --launch pixel_5

# Or from Android Studio: Tools > AVD Manager

# Run app
flutter run -d emulator-5554

# View logs
flutter logs
```

### Running on Physical Device
```bash
# Enable USB Debugging on device
# Settings > Developer Options > USB Debugging

# Connect device
adb devices

# Run
flutter run -d <device-id>

# View device logs
adb logcat
```

### Build Process
1. Compile Dart to Kernel
2. Compile Kernel to native code (ARM, ARM64, x86_64)
3. Bundle resources and assets
4. Create APK or App Bundle

### Release Signing
Before publishing to Google Play Store:
1. Create keystore (see SETUP.md)
2. Configure signing in build.gradle.kts
3. Build signed APK: `flutter build apk --release`
4. Build App Bundle: `flutter build appbundle --release`

### Testing Considerations
- Test on multiple devices/API levels
- Test landscape/portrait orientations
- Test with low battery mode enabled
- Test offline functionality
- Test on different screen sizes

### Common Android Issues
| Issue | Solution |
|-------|----------|
| Build fails with "no connected devices" | Connect device or start emulator |
| Keystore password error | Check android/local.properties |
| "Module error" | Run `flutter clean && flutter pub get` |
| ANR (Application Not Responding) | Profile with `--profile` flag |

### Android-Specific Plugins
```yaml
# For location services
geolocator: ^11.0.0
google_maps_flutter: ^2.5.0

# For background jobs
workmanager: ^0.5.0

# For local notifications
flutter_local_notifications: ^16.0.0

# For camera/gallery
image_picker: ^1.0.0
```

---

## iOS Platform

### Key Differences
- Requires macOS and Xcode
- Uses Swift for native iOS interop
- File system: app-specific sandboxed directory
- Background execution: Limited by iOS restrictions

### Minimum Requirements
- **Min Deployment Target**: iOS 12.0
- **Xcode**: 14.0 or later
- **macOS**: 11.0 or later
- **Swift Version**: 5.7+

### iOS-Specific Configuration
```swift
// ios/Podfile
- iOS 12.0 deployment target
- CocoaPods dependency manager
- Flutter framework integration

// ios/Runner.xcodeproj
- Bundle identifier: com.example.simpleCoachingBoard
- Team ID (for signing)
- Signing certificates
```

### Running on Simulator
```bash
# List available simulators
xcrun simctl list devices

# Run app
flutter run -d <simulator-id>

# Or open Xcode simulator directly
open -a Simulator

# View logs
flutter logs
```

### Running on Physical Device
```bash
# Connect device via USB
# Trust developer on device: Settings > General > Device Management

# List devices
flutter devices

# Run
flutter run -d <device-id>

# View logs
flutter logs
```

### Build Process
1. Compile Dart to Kernel
2. Compile Kernel to Arm64/x86_64 native code
3. Link against iOS frameworks
4. Create .app bundle
5. For release: Create .ipa archive

### Release Configuration
Before publishing to App Store:
1. Get Apple Developer Account
2. Create App ID and provisioning profiles
3. Configure signing in Xcode
4. Build: `flutter build ipa --release`
5. Upload to TestFlight/App Store Connect

### iOS Build Variants
```bash
# Debug
flutter run

# Release (optimized, stripped symbols)
flutter build ios --release

# Archive for App Store
flutter build ipa --release
```

### Testing Considerations
- Test on different iPhone models and sizes
- Test on different iOS versions (minimum iOS 12)
- Test on iPad in both orientations
- Test with and without notch/Dynamic Island
- Test with low memory conditions
- Test accessibility features (VoiceOver, etc.)

### Common iOS Issues
| Issue | Solution |
|-------|----------|
| Pod installation fails | `cd ios && pod install && cd ..` |
| Code signing fails | Check Xcode signing configuration |
| Module error | Run `flutter clean` and build again |
| Symbol not found | Update CocoaPods: `pod repo update` |
| Build hangs | Check Console.app for compilation errors |

### iOS-Specific Plugins
```yaml
# For location services
geolocator: ^11.0.0
google_maps_flutter: ^2.5.0

# For background tasks (limited on iOS)
workmanager: ^0.5.0  # Uses BGProcessingTask

# For local notifications
flutter_local_notifications: ^16.0.0

# For push notifications
firebase_messaging: ^14.6.0

# For camera/gallery
image_picker: ^1.0.0
```

### iOS Restrictions
- Background execution limited to ~3 minutes
- Location updates require user permission
- Camera/microphone require info.plist entries
- Clipboard access requires permission
- Battery access limited

---

## Cross-Platform Considerations

### Platform-Specific Code
When you need platform-specific code, use platform channels:

```dart
// Dart side
import 'package:flutter/services.dart';

const platform = MethodChannel('com.example.app/channel');

try {
  final result = await platform.invokeMethod('getDeviceInfo');
} catch (e) {
  print('Error: $e');
}
```

```kotlin
// Android side (Kotlin)
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, 
      "com.example.app/channel")
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "getDeviceInfo" -> {
            result.success("Device info here")
          }
          else -> result.notImplemented()
        }
      }
  }
}
```

```swift
// iOS side (Swift)
import Flutter

@UIApplicationMain
@objc class GeneratedPluginRegistrant: NSObject {
  override class func dummyMethodToEnforceBundling() {
    let channel = FlutterMethodChannel(name: "com.example.app/channel",
                                       binaryMessenger: rootViewController.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getDeviceInfo":
        result("Device info here")
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
```

### Detecting Platform
```dart
import 'dart:io' show Platform;

if (Platform.isAndroid) {
  // Android-specific code
} else if (Platform.isIOS) {
  // iOS-specific code
} else if (kIsWeb) {
  // Web-specific code
}
```

### Platform-Specific Packages
```yaml
# Only for Android
android_alarm_manager_plus:
  platforms:
    android:

# Only for iOS
ios_platform_images:
  platforms:
    ios:

# Only for Web
universal_html:
  platforms:
    web:
```

---

## Testing Strategy

### Unit Tests
```bash
flutter test test/unit_test.dart
```
- Fast execution
- No device needed
- Test business logic

### Widget Tests
```bash
flutter test test/widget_test.dart
```
- Test UI components
- No device needed
- Simulate user interactions

### Integration Tests
```bash
flutter test integration_test/app_test.dart
```
- Test full app flow
- Requires device/emulator
- Slow but realistic

### Platform-Specific Testing

#### Android
```bash
# Run tests on specific device
flutter test -d emulator-5554

# Profile performance
flutter run --profile -d emulator-5554
```

#### iOS
```bash
# Run tests on simulator
flutter test -d ios-simulator

# Run on physical device
flutter test -d <device-id>
```

#### Web
```bash
# Test in Chrome
flutter test -d chrome

# Test in Firefox
flutter test -d firefox
```

---

## Deployment Checklist by Platform

### Web
- [ ] Build with `flutter build web --release`
- [ ] Test on all major browsers
- [ ] Check PWA features work offline
- [ ] Verify GitHub Pages deployment
- [ ] Monitor bundle size
- [ ] Test on mobile browsers

### Android
- [ ] Test on API 21+ devices
- [ ] Test on multiple screen sizes
- [ ] Verify signing configuration
- [ ] Build App Bundle: `flutter build appbundle --release`
- [ ] Upload to Google Play Console
- [ ] Configure store listing
- [ ] Test on real device before release

### iOS
- [ ] Test on iPhone and iPad
- [ ] Test on iOS 12+ versions
- [ ] Configure app signing in Xcode
- [ ] Build IPA: `flutter build ipa --release`
- [ ] Upload to App Store Connect
- [ ] Configure store listing
- [ ] Submit for review
- [ ] Test TestFlight version

---

## Resources by Platform

### Web
- [Flutter Web Documentation](https://flutter.dev/multi-platform/web)
- [Web Performance Guide](https://flutter.dev/docs/perf/web-performance)
- [PWA Support](https://flutter.dev/docs/deployment/web#pwa-support)

### Android
- [Flutter Android Documentation](https://flutter.dev/multi-platform/android)
- [Android Studio Setup](https://developer.android.com/studio)
- [Google Play Console](https://play.google.com/console)
- [Android Gradle Plugin Documentation](https://developer.android.com/studio/releases/gradle-plugin)

### iOS
- [Flutter iOS Documentation](https://flutter.dev/multi-platform/ios)
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [iOS Developer Program](https://developer.apple.com/programs/ios/)

### Cross-Platform
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Pub Package Manager](https://pub.dev)
