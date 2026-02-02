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
    // OneSignal Flutter SDK handles threading internally
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
  
  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
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
    
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
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

## Demo Welcome View (Flutter)

When using the demo App ID, create this view:

### welcome_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _showSuccess = false;
  
  final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');
  
  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }
  
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value)) {
      return 'Use format: +1234567890';
    }
    return null;
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text;
      final phone = _phoneController.text;
      
      OneSignal.User.addEmail(email);
      OneSignal.User.addSms(phone);
      OneSignal.User.addTagWithKey('demo_user', 'true');
      OneSignal.User.addTagWithKey('welcome_sent', DateTime.now().millisecondsSinceEpoch.toString());
      
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneSignal Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _showSuccess ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }
  
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'OneSignal Integration Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your details to receive a welcome message',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'you@example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1 555 123 4567',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Welcome Message'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Success!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your email and phone for a welcome message!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
```

### Cupertino Version (iOS-style)

```dart
import 'package:flutter/cupertino.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class WelcomeScreenCupertino extends StatefulWidget {
  const WelcomeScreenCupertino({super.key});

  @override
  State<WelcomeScreenCupertino> createState() => _WelcomeScreenCupertinoState();
}

class _WelcomeScreenCupertinoState extends State<WelcomeScreenCupertino> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _showSuccess = false;
  String? _emailError;
  String? _phoneError;
  
  final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');
  
  bool get _isFormValid {
    final email = _emailController.text;
    final phone = _phoneController.text;
    return _emailRegex.hasMatch(email) && _phoneRegex.hasMatch(phone);
  }
  
  void _validateFields() {
    setState(() {
      final email = _emailController.text;
      final phone = _phoneController.text;
      
      _emailError = email.isNotEmpty && !_emailRegex.hasMatch(email)
          ? 'Enter a valid email address'
          : null;
      _phoneError = phone.isNotEmpty && !_phoneRegex.hasMatch(phone)
          ? 'Use format: +1234567890'
          : null;
    });
  }
  
  Future<void> _submitForm() async {
    if (!_isFormValid) return;
    
    setState(() => _isLoading = true);
    
    final email = _emailController.text;
    final phone = _phoneController.text;
    
    OneSignal.User.addEmail(email);
    OneSignal.User.addSms(phone);
    OneSignal.User.addTagWithKey('demo_user', 'true');
    OneSignal.User.addTagWithKey('welcome_sent', DateTime.now().millisecondsSinceEpoch.toString());
    
    setState(() {
      _isLoading = false;
      _showSuccess = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('OneSignal Demo'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _showSuccess ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }
  
  Widget _buildFormView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'OneSignal Integration Complete!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CupertinoTextField(
          controller: _emailController,
          placeholder: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _validateFields(),
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(CupertinoIcons.mail),
          ),
        ),
        if (_emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_emailError!, style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 12)),
          ),
        const SizedBox(height: 16),
        CupertinoTextField(
          controller: _phoneController,
          placeholder: 'Phone Number (+1234567890)',
          keyboardType: TextInputType.phone,
          onChanged: (_) => _validateFields(),
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(CupertinoIcons.phone),
          ),
        ),
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_phoneError!, style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 12)),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: _isFormValid && !_isLoading ? _submitForm : null,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('Send Welcome Message'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.check_mark_circled_solid, size: 80, color: CupertinoColors.activeGreen),
        const SizedBox(height: 24),
        const Text('Success!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Check your email and phone for a welcome message!',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
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
