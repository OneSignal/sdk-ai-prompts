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
- [ ] `google-services.json` in `android/app/` (if using FCM)
- [ ] Google Services plugin configured in `android/build.gradle`

### iOS Sub-Project

- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes capability with Remote notifications
- [ ] Minimum deployment target iOS 11.0+
- [ ] APNs key/certificate uploaded to OneSignal dashboard
- [ ] Run `pod install` in `ios/` directory

### Initialization

- [ ] OneSignal initialized in `main()` before `runApp()`
- [ ] Initialize on both platforms simultaneously

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
  
  // Request notification permission
  OneSignal.Notifications.requestPermission(true);
  
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

## Push Subscription Observer + Welcome Dialog (Flutter)

After completing the integration, add a push subscription observer that shows a dialog when the device receives a push subscription ID.

### Material

```dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void setupPushSubscriptionObserver(BuildContext context) {
  OneSignal.User.pushSubscription.addObserver((state) {
    final previousId = state.previous.id;
    final currentId = state.current.id;

    if ((previousId == null || previousId.isEmpty) && currentId != null && currentId.isNotEmpty) {
      showWelcomeDialog(context);
    }
  });
}

void showWelcomeDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Your OneSignal integration is complete!'),
      content: const Text('Click the button below to trigger your first journey via an in-app message.'),
      actions: [
        TextButton(
          onPressed: () {
            OneSignal.InAppMessages.addTrigger("ai_implementation_campaign_email_journey", "true");
            Navigator.pop(context);
          },
          child: const Text('Trigger your first journey'),
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

void setupPushSubscriptionObserver(BuildContext context) {
  OneSignal.User.pushSubscription.addObserver((state) {
    final previousId = state.previous.id;
    final currentId = state.current.id;

    if ((previousId == null || previousId.isEmpty) && currentId != null && currentId.isNotEmpty) {
      showWelcomeDialog(context);
    }
  });
}

void showWelcomeDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Your OneSignal integration is complete!'),
      content: const Text('Click the button below to trigger your first journey via an in-app message.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            OneSignal.InAppMessages.addTrigger("ai_implementation_campaign_email_journey", "true");
            Navigator.pop(context);
          },
          child: const Text('Trigger your first journey'),
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
| Notifications not received | Check both Android and iOS platform configurations |
| Hot reload breaks OneSignal | Restart app completely after OneSignal changes |
