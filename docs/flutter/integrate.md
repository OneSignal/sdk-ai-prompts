# Flutter Platform Integration

## Official Documentation

* [OneSignal Flutter SDK Setup](https://documentation.onesignal.com/docs/flutter-sdk-setup)
* [Flutter SDK API Reference](https://pub.dev/documentation/onesignal_flutter/latest/)
* [Pub.dev Package](https://pub.dev/packages/onesignal_flutter)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-Flutter-SDK)

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Flutter Configuration

- [ ] Minimum Flutter SDK version 2.0.0 or higher
- [ ] Dart SDK version 2.12.0 or higher (null safety)

### Android Sub-Project

- [ ] `minSdkVersion` 21+ in `android/app/build.gradle`
- [ ] `compileSdkVersion` 33+ in `android/app/build.gradle`
- [ ] INTERNET permission in `android/app/src/main/AndroidManifest.xml`

Note: The OneSignal SDK handles FCM registration itself. Do NOT add the Google Services Gradle plugin or a `google-services.json` file — they are not required. Push credentials (the Firebase Service Account JSON) are configured in the OneSignal dashboard, not in the app.

### iOS Sub-Project

- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes capability with Remote notifications
- [ ] App Groups capability configured on BOTH Runner and `OneSignalNotificationServiceExtension`
- [ ] `OneSignalNotificationServiceExtension` target added and configured
- [ ] Minimum deployment target iOS 12.0+
- [ ] APNs key/certificate uploaded to OneSignal dashboard
- [ ] Run `pod install` in `ios/` directory

### Initialization

- [ ] OneSignal initialized in `main()` before `runApp()`
- [ ] Initialize on both platforms simultaneously

---

## iOS Push Infrastructure

Flutter apps include a native iOS project under `ios/`. Complete the "Shared iOS Push Infrastructure" section earlier in this document. It is required for the Notification Service Extension, App Group, Background Modes, entitlements, and Confirmed Delivery/rich notification support.

Flutter-specific notes:

* The main iOS app target is usually `Runner`
* The Xcode project is usually `ios/Runner.xcodeproj`
* Add the App Group to `Runner.entitlements` (or create one if the project does not have it yet)
* Add a `OneSignalNotificationServiceExtension` target to the same Xcode project
* If CocoaPods is used, add the NSE target block to `ios/Podfile` and run `cd ios && pod install && cd ..`

```ruby
target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignalXCFramework', '~> 5.0'
end
```

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

## Threading Model

Flutter handles threading differently - most OneSignal operations are already async.
Use `Future`s and `async/await` for all OneSignal calls:

```dart
class OneSignalService {
  Future<void> initialize(String appId) async {
    // Set log level for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    // Initialize OneSignal
    OneSignal.initialize(appId);
  }
  
  Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }
}
```

For heavy computation, use `compute()` or `Isolate`:

```dart
// If you need to process notification data
final result = await compute(processNotificationData, data);
```

---

## Code Examples

### Dependency (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  onesignal_flutter: ^5.0.0
```

Then run:
```bash
flutter pub get
```

### Main Entry Point (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set log level for debugging (remove in production)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  // Initialize OneSignal
  OneSignal.initialize("YOUR_ONESIGNAL_APP_ID");

  // Do NOT request push permission here — the verification dialog
  // (see "Push Subscription Verification Dialog") requests it on tap.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: const HomeScreen(),
    );
  }
}
```

### Centralized Service (onesignal_service.dart)

```dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();
  
  bool _isInitialized = false;
  
  void initialize(String appId) {
    if (_isInitialized) return;
    
    // Set log level for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    // Initialize OneSignal
    OneSignal.initialize(appId);
    _isInitialized = true;
  }
  
  void login(String externalId) {
    OneSignal.login(externalId);
  }
  
  void logout() {
    OneSignal.logout();
  }
  
  void setEmail(String email) {
    OneSignal.User.addEmail(email);
  }
  
  void setSmsNumber(String number) {
    OneSignal.User.addSms(number);
  }
  
  void setTag(String key, String value) {
    OneSignal.User.addTagWithKey(key, value);
  }
  
  Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }
  
  void setLogLevel(OSLogLevel level) {
    OneSignal.Debug.setLogLevel(level);
  }
  
  // Listen for notification events
  void setNotificationClickListener(void Function(OSNotificationClickEvent) handler) {
    OneSignal.Notifications.addClickListener(handler);
  }
  
  void setNotificationForegroundListener(void Function(OSNotificationWillDisplayEvent) handler) {
    OneSignal.Notifications.addForegroundWillDisplayListener(handler);
  }
}
```

### Provider Pattern (notification_provider.dart)

```dart
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationProvider extends ChangeNotifier {
  final OneSignalService _oneSignalService = OneSignalService();
  
  bool _isPermissionGranted = false;
  bool get isPermissionGranted => _isPermissionGranted;
  
  void initialize(String appId) {
    _oneSignalService.initialize(appId);
    _setupListeners();
  }
  
  void _setupListeners() {
    _oneSignalService.setNotificationClickListener((event) {
      // Handle notification click
      debugPrint('Notification clicked: ${event.notification.title}');
    });
  }
  
  Future<void> requestPermission() async {
    _isPermissionGranted = await _oneSignalService.requestPermission();
    notifyListeners();
  }
  
  void setUserDetails(String email, String phone) {
    _oneSignalService.setEmail(email);
    _oneSignalService.setSmsNumber(phone);
  }
}
```

---

## Push Subscription Verification Dialog

After completing SDK initialization, add a push subscription observer so the app can confirm that the device registered successfully. When the subscription ID is received, show a dialog and request push permission on tap.

### Material

```dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

bool _dialogShown = false;

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
bool _isRegistered(String? id) =>
    id != null && id.isNotEmpty && !id.startsWith('local-');

void _maybeShowIntegrationCompleteDialog(BuildContext context, String? subscriptionId) {
  if (_isRegistered(subscriptionId) && !_dialogShown) {
    _dialogShown = true;
    showIntegrationCompleteDialog(context);
  }
}

void setupPushSubscriptionObserver(BuildContext context) {
  OneSignal.User.pushSubscription.addObserver((state) {
    _maybeShowIntegrationCompleteDialog(context, state.current.id);
  });

  // The ID may already be assigned before the observer attaches,
  // so evaluate the current value immediately as well.
  _maybeShowIntegrationCompleteDialog(context, OneSignal.User.pushSubscription.id);
}

void showIntegrationCompleteDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Your OneSignal SDK integration is complete!'),
      content: const Text('You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            OneSignal.Notifications.requestPermission(true);
          },
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
```

### Cupertino

```dart
import 'package:flutter/cupertino.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

bool _dialogShown = false;

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
bool _isRegistered(String? id) =>
    id != null && id.isNotEmpty && !id.startsWith('local-');

void _maybeShowIntegrationCompleteDialog(BuildContext context, String? subscriptionId) {
  if (_isRegistered(subscriptionId) && !_dialogShown) {
    _dialogShown = true;
    showIntegrationCompleteDialog(context);
  }
}

void setupPushSubscriptionObserver(BuildContext context) {
  OneSignal.User.pushSubscription.addObserver((state) {
    _maybeShowIntegrationCompleteDialog(context, state.current.id);
  });

  // The ID may already be assigned before the observer attaches,
  // so evaluate the current value immediately as well.
  _maybeShowIntegrationCompleteDialog(context, OneSignal.User.pushSubscription.id);
}

void showIntegrationCompleteDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Your OneSignal SDK integration is complete!'),
      content: const Text('You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context);
            OneSignal.Notifications.requestPermission(true);
          },
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| iOS build fails | Run `cd ios && pod install --repo-update` |
| Android build fails | Check `minSdkVersion` is 21+ and sync gradle |
| Permission not working on iOS | Verify Push Notification capability in Xcode |
| iOS push received but no image | Verify the shared iOS Notification Service Extension and App Group setup |
| iOS Confirmed Delivery missing | Verify the shared App Group matches byte-for-byte in Runner and NSE entitlements, and confirm the OneSignal plan supports dashboard display |
| Notifications not received | Check both Android and iOS platform configurations |
| Hot reload breaks OneSignal | Restart app completely after OneSignal changes |
