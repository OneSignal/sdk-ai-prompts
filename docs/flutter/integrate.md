# Flutter Platform Integration

## Official Documentation

* [OneSignal Flutter SDK Setup](https://documentation.onesignal.com/docs/flutter-sdk-setup)
* [Flutter SDK API Reference](https://pub.dev/documentation/onesignal_flutter/latest/)
* [Pub.dev Package](https://pub.dev/packages/onesignal_flutter)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-Flutter-SDK)

If this file and the official [Flutter SDK setup](https://documentation.onesignal.com/docs/en/flutter-sdk-setup) page disagree, follow the official page.

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Flutter Configuration

- [ ] Flutter 3.29.0 or higher, per the official setup guide. If the project's Flutter is older, report it in the summary; don't upgrade it.

### Android Sub-Project

- [ ] Keep the project's `minSdkVersion` (Flutter's default `flutter.minSdkVersion` is fine). Only if Firebase Installation ID registration is on (see shared **Android Firebase Configuration**) does it need 23+, because `firebase-messaging` 25.x requires it.
- [ ] Don't change the Android Gradle Plugin version. If the build reports an incompatible AGP, recommend updating Android Studio (or ask before lowering AGP).
- [ ] INTERNET permission in `android/app/src/main/AndroidManifest.xml`

### Android Firebase Configuration

Follow **Android Firebase Configuration** in the shared guidelines (rules, the Step 1 question, and handling the answer). Flutter specifics, from the official [Flutter SDK setup](https://documentation.onesignal.com/docs/en/flutter-sdk-setup) and [Android Firebase credentials](https://documentation.onesignal.com/docs/en/android-firebase-credentials) pages:

- [ ] Expected location: `android/app/google-services.json`. Takes effect from `onesignal_flutter` 5.7.2.
- [ ] `android/settings.gradle` lists `google()` under `pluginManagement { repositories }`. Otherwise the build fails with `Plugin [id: 'com.google.gms.google-services'] was not found`.
- [ ] Declare the plugin in `android/settings.gradle`:
  ```groovy
  plugins {
      id "com.google.gms.google-services" version "[4.4.2, 4.99.99]" apply false
  }
  ```
  With `settings.gradle.kts`, use `id("com.google.gms.google-services") version "[4.4.2, 4.99.99]" apply false`.
- [ ] Apply it in `android/app/build.gradle` with `apply plugin: 'com.google.gms.google-services'`. With `build.gradle.kts`, add `id("com.google.gms.google-services")` to its `plugins` block. **This step is required:** the OneSignal Flutter plugin can't apply it, and without it the file does nothing.
- [ ] Only apply the plugin once the file is present; otherwise the build fails.
- [ ] Confirm the file took effect: from `android/`, run `./gradlew :app:processDebugGoogleServices`, then check that `google_app_id` and `project_id` appear under `android/app/build/generated/res/`.

### iOS Sub-Project

- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes capability with Remote notifications
- [ ] App Groups capability configured on BOTH Runner and `OneSignalNotificationServiceExtension`
- [ ] `OneSignalNotificationServiceExtension` target added and configured
- [ ] Minimum deployment target iOS 15.0+ on Runner and the NSE (official guide); don't lower an existing higher target
- [ ] CocoaPods projects: `pod install` succeeds for Runner + NSE; SPM projects: NSE links/builds without adding an NSE-only Podfile

### Initialization

- [ ] OneSignal initialized in `main()`, right after `runApp()`, as in the official setup guide
- [ ] Push permission requested right after initialization with `requestPermission(false)` (see **Push Permission Request**)
- [ ] Apply native iOS and/or Android project work only for the platforms selected in Step 1

### Notification Icons (Android, Recommended)

- [ ] Recommend in the summary adding a small icon named `ic_stat_onesignal_default` under `android/app/src/main/res/drawable-*`. Guide: https://documentation.onesignal.com/docs/en/notification-icons. Don't generate icons unless asked.

---

## iOS Push Infrastructure

Flutter apps include a native iOS project under `ios/`. Complete the "Shared iOS Push Infrastructure" section earlier in this document. It is required for the Notification Service Extension, App Group, Background Modes, entitlements, and Confirmed Delivery/rich notification support.

Flutter-specific notes:

* Detect the iOS Xcode project under `ios/` (usually `ios/Runner.xcodeproj` / target `Runner`). If the project or app target uses a different name, record that name and use it for all later NSE, App Group, and Podfile steps — do not assume `Runner` when the project clearly differs.
* Add the App Group to the main app target's entitlements (often `Runner.entitlements`; create one if missing), using the **existing** main-app bundle identifier already in the project
* Add a `OneSignalNotificationServiceExtension` target to the same Xcode project
* **Preserve the project's iOS dependency manager** (CocoaPods vs Swift Package Manager). Do not migrate between them unless the user asks.

### CocoaPods projects

If the app already uses CocoaPods (`ios/Podfile` present):

* Ensure the Podfile is a **full** Flutter Podfile that installs pods for the main app target via `flutter_install_all_ios_pods` (or the project's existing equivalent). Do **not** replace it with an NSE-only Podfile.
* Add the NSE target block and run `cd ios && pod install && cd ..`:

```ruby
target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignalXCFramework', '>= 5.0.0', '< 6.0'
end
```

This must match what `onesignal_flutter`'s podspec requests: the aggregate pod by default, or `OneSignalXCFramework/OneSignal` plus `OneSignalXCFramework/OneSignalInAppMessages` when `ONESIGNAL_DISABLE_LOCATION=true` (see the shared **CocoaPods projects — Podfile block**). A mismatch fails the build with "Multiple commands produce".

Prefer nesting the NSE target under the main app target with `inherit! :search_paths` when that matches the project's Podfile style and avoids duplicate OneSignal framework copies.

### Swift Package Manager projects

If the app uses SPM for iOS (no CocoaPods `Podfile`, or Flutter SPM enabled):

* Do **not** create a CocoaPods `Podfile` solely to satisfy the NSE.
* Create the NSE target, App Group, and `NotificationService` implementation (`import OneSignalExtension`) as in the shared iOS push infrastructure section.
* Per OneSignal Flutter setup docs, when SPM is in use you typically **skip** adding an NSE Podfile dependency — the OneSignal packages resolved for the app are expected to cover the extension import path.
* If the NSE build fails with `No such module 'OneSignalExtension'`, explicitly link the **`OneSignalExtension`** product from `OneSignal-XCFramework` to the NSE target (same pattern as native iOS SPM). Do not work around this by adding an NSE-only Podfile to an SPM app.

---

## Architecture Guidance

### Provider/Riverpod

```
lib/
├── main.dart
├── providers/
│   └── notification_provider.dart    # OneSignal provider
├── services/
│   └── onesignal_service.dart        # OneSignal wrapper
└── screens/
    └── ...
```

### BLoC

```
lib/
├── main.dart
├── core/
│   └── services/
│       └── onesignal_service.dart
├── features/
│   └── notification/
│       ├── bloc/
│       └── ...
```

### GetX

```
lib/
├── main.dart
├── app/
│   └── services/
│       └── onesignal_service.dart
└── ...
```

### Simple/No Architecture

```
lib/
├── main.dart
├── services/
│   └── onesignal_service.dart
└── ...
```

---

## Code Examples

### Dependency (pubspec.yaml)

Use the Current version from releases.json (Step 2) with a caret constraint, as the official guide does (`^5.7.2` at the time of writing):

```yaml
dependencies:
  flutter:
    sdk: flutter
  onesignal_flutter: ^X.Y.Z
```

Then run:
```bash
flutter pub get
```

Report the resolved version from `pubspec.lock` in the summary.

### Centralized Service (onesignal_service.dart)

Wraps every OneSignal call. Initialization only: no login, email, SMS, or tag methods (see **Scope: initialization only** in the shared guidelines).

```dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _isInitialized = false;

  void initialize(String appId) {
    if (_isInitialized) return;

    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(appId);
    _isInitialized = true;
  }

  /// Shows the native prompt. false = don't fall back to Settings, as in the official guide.
  void requestPushPermission() {
    OneSignal.Notifications.requestPermission(false);
  }

  void setLogLevel(OSLogLevel level) {
    OneSignal.Debug.setLogLevel(level);
  }
}
```

### Main Entry Point (main.dart)

Follows the official setup guide: initialize and request permission in `main()`, right after `runApp()`. Replace `YOUR_APP_ID` with the App ID from Step 1.

```dart
import 'package:flutter/material.dart';
import 'services/onesignal_service.dart';

void main() {
  runApp(const MyApp());

  OneSignalService().initialize("YOUR_APP_ID");
  OneSignalService().requestPushPermission();
}
```

Keep the project's existing `main()` contents (for example `WidgetsFlutterBinding.ensureInitialized()` or other setup); only add the two OneSignal calls after `runApp()`.

---

## Push Permission Request

Follow the official setup guide: request push permission in `main()`, right after initialization, through the service, with `requestPermission(false)`. Don't add a verification dialog, and don't request permission anywhere else.

In the Changes Summary, mention the official guide's advice: in production, consider prompting with an in-app message instead, for better opt-in rates.

If the developer skipped the App ID, still add the permission request, and include this alert at the top of the Changes Summary, next to the App ID reminder:

> **The app will show the push permission prompt at launch, but the device won't register with OneSignal until you set your App ID.** Users who accept now won't be reachable until a build with your real App ID ships.

---

## Verification

Give the developer these steps in the Changes Summary, following the official guide:

1. Run the app on a device or emulator (`flutter run`). Android needs a device or emulator with Google Play Services.
2. In the OneSignal dashboard, open **Audience → Users & subscriptions → Subscriptions**. The new Subscription shows **Never Subscribed**.
3. Accept the permission prompt in the app.
4. Refresh the dashboard. The status changes to **Subscribed**.
5. Send a test push. This needs FCM credentials (Android) and APNs credentials (iOS) in the OneSignal dashboard.

Do **not** reinstall or wipe the app just to re-check; that creates a second OneSignal subscription. See shared guidelines: **Verification without duplicate subscriptions**.

---

## After Setup: Push Credentials in OneSignal

In the Changes Summary, for each platform selected in Step 1:

- **Android:** use the shared **After setup: FCM credentials in OneSignal** note.
- **iOS:** > **Push won't reach iOS devices until your OneSignal app has APNs credentials.** In OneSignal, go to **Settings → Push & In-App → Apple iOS (APNs)** and add your p8 Auth Key (recommended) or p12 Certificate.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| iOS build fails | Run `cd ios && pod install --repo-update` |
| `Multiple commands produce '.../XCFrameworkIntermediates/OneSignalXCFramework/...'` | The NSE and the app request different `OneSignalXCFramework` subspecs. Make the NSE block match the plugin's podspec (see **CocoaPods projects**), then `pod install` |
| Android build fails | Sync Gradle and check the error; if it mentions `minSdkVersion`, raise it to what the error asks |
| `Plugin [id: 'com.google.gms.google-services'] was not found` | Add `google()` to `pluginManagement { repositories }` in `android/settings.gradle` |
| Incompatible AGP version | Update Android Studio; ask before lowering AGP |
| Permission prompt never appears | Confirm `requestPushPermission()` runs after `initialize` in `main()`. If the user already answered, the OS won't prompt again |
| iOS push received but no image | Verify the shared iOS Notification Service Extension and App Group setup |
| iOS Confirmed Delivery missing | Verify the shared App Group matches byte-for-byte in Runner and NSE entitlements, and confirm the OneSignal plan supports dashboard display |
| Android subscription status -32 or -33 | google-services.json missing, or from a different Firebase project than the FCM Service Account in OneSignal |
| Hot reload breaks OneSignal | Restart app completely after OneSignal changes |
