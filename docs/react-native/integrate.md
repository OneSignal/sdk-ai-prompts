# React Native Integration Guide

## Official Documentation

* [OneSignal React Native SDK Setup](https://documentation.onesignal.com/docs/react-native-sdk-setup)
* [React Native SDK API Reference](https://documentation.onesignal.com/docs/react-native-sdk-api-reference)
* [NPM Package](https://www.npmjs.com/package/react-native-onesignal)
* [GitHub Repository](https://github.com/OneSignal/react-native-onesignal)

---

## User Prompts

Before beginning the integration, ask the user the following question:

> **Language Preference**: Do you want the integration code in JavaScript or TypeScript?

Use the user's response to determine which code examples to provide throughout the integration.

---

## Important: Bare React Native Workflow

> **This guide is for bare React Native projects** (created with `npx react-native init` or `npx @react-native-community/cli init`).
>
> For Expo managed workflow projects, use the [Expo SDK Setup](../react-native-expo/ai-prompt.md) instead.
>
> **Requirements:**
> - React Native 0.71+ (recommended: 0.76+)
> - iOS: macOS with Xcode 14+ and CocoaPods 1.16+
> - Android: Android 7.0+ device or emulator with Google Play Services

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Project Requirements

- [ ] React Native 0.71 or higher
- [ ] iOS minimum deployment target is iOS 12.0 or higher
- [ ] Android `minSdkVersion` is 21 or higher (24+ recommended)
- [ ] Android `compileSdkVersion` is 33 or higher

### OneSignal Dashboard

- [ ] OneSignal App ID obtained from dashboard
- [ ] iOS: APNs key (.p8) or certificate (.p12) uploaded to OneSignal dashboard
- [ ] Android: FCM credentials configured (Firebase Server Key or Service Account JSON)

### iOS Configuration (in Xcode)

- [ ] Push Notifications capability enabled
- [ ] Background Modes capability enabled with "Remote notifications" checked
- [ ] App Groups capability configured
- [ ] Notification Service Extension added and configured

### Android Configuration

- [ ] `google-services.json` placed in `android/app/` directory (if using FCM)
- [ ] Notification icons configured (optional but recommended)

### Initialization

- [ ] OneSignal initialized in `App.tsx` or `App.js` (root component)
- [ ] Initialization happens before rendering main app content

---

## Installation

Install the OneSignal React Native SDK:

```bash
npm install --save react-native-onesignal
```

Or with Yarn:

```bash
yarn add react-native-onesignal
```

> **Note:** React Native 0.60+ supports autolinking, so no manual linking is required.

---

## SDK Initialization

Add OneSignal initialization to your root component (`App.tsx` or `App.js`):

### TypeScript Version (App.tsx)

```typescript
import React, { useEffect } from 'react';
import { View, Text } from 'react-native';
import { OneSignal, LogLevel } from 'react-native-onesignal';

// Replace with your OneSignal App ID
const ONESIGNAL_APP_ID = 'YOUR_ONESIGNAL_APP_ID';

function App(): React.JSX.Element {
  useEffect(() => {
    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);

    // Initialize OneSignal with your App ID
    OneSignal.initialize(ONESIGNAL_APP_ID);

    // Request push notification permission
    // Recommended: Remove after testing and use In-App Messages to prompt instead
    OneSignal.Notifications.requestPermission(false);
  }, []);

  return (
    <View>
      <Text>Your App Content</Text>
    </View>
  );
}

export default App;
```

### JavaScript Version (App.js)

```javascript
import React, { useEffect } from 'react';
import { View, Text } from 'react-native';
import { OneSignal, LogLevel } from 'react-native-onesignal';

// Replace with your OneSignal App ID
const ONESIGNAL_APP_ID = 'YOUR_ONESIGNAL_APP_ID';

function App() {
  useEffect(() => {
    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);

    // Initialize OneSignal with your App ID
    OneSignal.initialize(ONESIGNAL_APP_ID);

    // Request push notification permission
    // Recommended: Remove after testing and use In-App Messages to prompt instead
    OneSignal.Notifications.requestPermission(false);
  }, []);

  return (
    <View>
      <Text>Your App Content</Text>
    </View>
  );
}

export default App;
```

---

## Android Setup

Android setup is minimal thanks to React Native autolinking. The SDK will be automatically linked when you run your Android build.

### 1. Configure Firebase (Required for FCM)

If you're using Firebase Cloud Messaging (FCM), ensure your `google-services.json` file is placed in `android/app/`.

### 2. Configure Notification Icons (Optional)

Create custom notification icons in your Android resources:

```
android/app/src/main/res/
├── drawable-hdpi/
│   └── ic_stat_onesignal_default.png (24x24)
├── drawable-mdpi/
│   └── ic_stat_onesignal_default.png (16x16)
├── drawable-xhdpi/
│   └── ic_stat_onesignal_default.png (32x32)
├── drawable-xxhdpi/
│   └── ic_stat_onesignal_default.png (48x48)
├── drawable-xxxhdpi/
│   └── ic_stat_onesignal_default.png (64x64)
```

### 3. Build for Android

```bash
npx react-native run-android
```

Or build directly:

```bash
cd android && ./gradlew assembleDebug
```

---

## iOS Setup

iOS requires additional configuration in Xcode. Follow these steps carefully.

### 1. Install CocoaPods Dependencies

```bash
cd ios && pod install && cd ..
```

### 2. Open Xcode Workspace

Always use the `.xcworkspace` file, not the `.xcodeproj`:

```bash
open ios/YourAppName.xcworkspace
```

### 3. Add Push Notifications Capability

1. Select your app target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Push Notifications**

### 4. Add Background Modes Capability

1. Click **+ Capability** again
2. Add **Background Modes**
3. Check **Remote notifications**

### 5. Add App Groups Capability

App Groups enable data sharing between your app and the Notification Service Extension (required for Confirmed Delivery and Badges).

1. Click **+ Capability**
2. Add **App Groups**
3. Click **+** to add a new container
4. Use this format: `group.YOUR_BUNDLE_ID.onesignal`
   - Example: For bundle ID `com.example.myapp`, use `group.com.example.myapp.onesignal`

### 6. Add Notification Service Extension

The Notification Service Extension (NSE) enables rich notifications, images, and Confirmed Delivery analytics.

1. In Xcode: **File → New → Target...**
2. Select **Notification Service Extension**, then click **Next**
3. Set Product Name to `OneSignalNotificationServiceExtension`
4. Click **Finish**
5. When prompted, click **Don't Activate** (keep your main scheme active)

### 7. Configure NSE Deployment Target

1. Select the `OneSignalNotificationServiceExtension` target
2. Go to **General** tab
3. Set **Minimum Deployment** to match your main app (iOS 12.0+ recommended)

### 8. Add App Groups to NSE Target

1. Select `OneSignalNotificationServiceExtension` target
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability
4. Select the **same App Group** you created in step 5

### 9. Update NSE Code

Replace the contents of `NotificationService.swift` (or `NotificationService.m`) in the `OneSignalNotificationServiceExtension` folder:

#### Swift Version (NotificationService.swift)

```swift
import UserNotifications
import OneSignalExtension

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            OneSignalExtension.didReceiveNotificationExtensionRequest(
                self.receivedRequest,
                with: bestAttemptContent,
                withContentHandler: self.contentHandler
            )
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(
                self.receivedRequest,
                with: self.bestAttemptContent
            )
            contentHandler(bestAttemptContent)
        }
    }
}
```

#### Objective-C Version (NotificationService.m)

```objc
#import <OneSignalExtension/OneSignalExtension.h>
#import "NotificationService.h"

@interface NotificationService ()
@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNNotificationRequest *receivedRequest;
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                   withContentHandler:(void (^)(UNNotificationContent *_Nonnull))contentHandler {
    self.receivedRequest = request;
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];

    [OneSignalExtension didReceiveNotificationExtensionRequest:self.receivedRequest
                                       withMutableNotificationContent:self.bestAttemptContent
                                                   withContentHandler:self.contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
    [OneSignalExtension serviceExtensionTimeWillExpireRequest:self.receivedRequest
                                  withMutableNotificationContent:self.bestAttemptContent];
    self.contentHandler(self.bestAttemptContent);
}

@end
```

### 10. Add OneSignal to Podfile

Add the Notification Service Extension target to your `ios/Podfile`:

```ruby
# Add this after your main app target's "end"

target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignalXCFramework', '>= 5.0.0', '< 6.0'
end
```

### 11. Install Pods

```bash
cd ios && pod install && cd ..
```

### 12. Build for iOS

```bash
npx react-native run-ios
```

Or build from Xcode using the **Run** button.

---

## Demo Welcome View

When using a demo App ID for testing, you can use this welcome screen to verify the integration:

### JavaScript Version (WelcomeScreen.js)

```javascript
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { OneSignal } from 'react-native-onesignal';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function WelcomeScreen() {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [errors, setErrors] = useState({});

  const isEmailValid = EMAIL_REGEX.test(email);
  const isFormValid = isEmailValid;

  const validateFields = () => {
    const newErrors = {};
    if (email && !isEmailValid) {
      newErrors.email = 'Enter a valid email address';
    }
    setErrors(newErrors);
  };

  const handleSubmit = async () => {
    if (!isFormValid) return;

    setIsLoading(true);

    try {
      OneSignal.User.addEmail(email);
      OneSignal.User.addTag('demo_user', 'true');
      OneSignal.User.addTag('welcome_sent', Date.now().toString());

      await new Promise((resolve) => setTimeout(resolve, 500));
      setShowSuccess(true);
    } catch (error) {
      console.error('Error submitting:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (showSuccess) {
    return (
      <View style={styles.successContainer}>
        <Text style={styles.checkmark}>✓</Text>
        <Text style={styles.successTitle}>Success!</Text>
        <Text style={styles.successMessage}>
          Check your email for a welcome message!
        </Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.title}>OneSignal Integration Complete!</Text>
          <Text style={styles.subtitle}>
            Enter your details to receive a welcome message
          </Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputContainer}>
            <Text style={styles.label}>Email Address</Text>
            <TextInput
              style={[styles.input, errors.email && styles.inputError]}
              value={email}
              onChangeText={setEmail}
              onBlur={validateFields}
              placeholder="you@example.com"
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
            />
            {errors.email && <Text style={styles.errorText}>{errors.email}</Text>}
          </View>

          <TouchableOpacity
            style={[styles.button, !isFormValid && styles.buttonDisabled]}
            onPress={handleSubmit}
            disabled={!isFormValid || isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Send Welcome Message</Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 24,
  },
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  form: {
    width: '100%',
  },
  inputContainer: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    backgroundColor: '#f9f9f9',
  },
  inputError: {
    borderColor: '#e74c3c',
  },
  errorText: {
    color: '#e74c3c',
    fontSize: 12,
    marginTop: 4,
  },
  button: {
    backgroundColor: '#6c5ce7',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonDisabled: {
    backgroundColor: '#bbb',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  successContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
    backgroundColor: '#fff',
  },
  checkmark: {
    fontSize: 64,
    color: '#27ae60',
    marginBottom: 16,
  },
  successTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  successMessage: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
});
```

### TypeScript Version (WelcomeScreen.tsx)

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { OneSignal } from 'react-native-onesignal';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

interface FormErrors {
  email?: string;
}

export const WelcomeScreen: React.FC = () => {
  const [email, setEmail] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [showSuccess, setShowSuccess] = useState<boolean>(false);
  const [errors, setErrors] = useState<FormErrors>({});

  const isEmailValid = EMAIL_REGEX.test(email);
  const isFormValid = isEmailValid;

  const validateFields = (): void => {
    const newErrors: FormErrors = {};
    if (email && !isEmailValid) {
      newErrors.email = 'Enter a valid email address';
    }
    setErrors(newErrors);
  };

  const handleSubmit = async (): Promise<void> => {
    if (!isFormValid) return;

    setIsLoading(true);

    try {
      OneSignal.User.addEmail(email);
      OneSignal.User.addTag('demo_user', 'true');
      OneSignal.User.addTag('welcome_sent', Date.now().toString());

      await new Promise((resolve) => setTimeout(resolve, 500));
      setShowSuccess(true);
    } catch (error) {
      console.error('Error submitting:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (showSuccess) {
    return (
      <View style={styles.successContainer}>
        <Text style={styles.checkmark}>✓</Text>
        <Text style={styles.successTitle}>Success!</Text>
        <Text style={styles.successMessage}>
          Check your email for a welcome message!
        </Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.title}>OneSignal Integration Complete!</Text>
          <Text style={styles.subtitle}>
            Enter your details to receive a welcome message
          </Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputContainer}>
            <Text style={styles.label}>Email Address</Text>
            <TextInput
              style={[styles.input, errors.email && styles.inputError]}
              value={email}
              onChangeText={setEmail}
              onBlur={validateFields}
              placeholder="you@example.com"
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
            />
            {errors.email && <Text style={styles.errorText}>{errors.email}</Text>}
          </View>

          <TouchableOpacity
            style={[styles.button, !isFormValid && styles.buttonDisabled]}
            onPress={handleSubmit}
            disabled={!isFormValid || isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Send Welcome Message</Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 24,
  },
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  form: {
    width: '100%',
  },
  inputContainer: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    backgroundColor: '#f9f9f9',
  },
  inputError: {
    borderColor: '#e74c3c',
  },
  errorText: {
    color: '#e74c3c',
    fontSize: 12,
    marginTop: 4,
  },
  button: {
    backgroundColor: '#6c5ce7',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonDisabled: {
    backgroundColor: '#bbb',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  successContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
    backgroundColor: '#fff',
  },
  checkmark: {
    fontSize: 64,
    color: '#27ae60',
    marginBottom: 16,
  },
  successTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  successMessage: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
});
```

---

## Advanced Patterns (Optional)

For larger applications, you may want to use one of these patterns:

### Context Provider Pattern

```typescript
// src/contexts/NotificationContext.tsx
import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { OneSignal, LogLevel } from 'react-native-onesignal';

interface NotificationContextType {
  isInitialized: boolean;
  hasPermission: boolean;
  requestPermission: () => Promise<boolean>;
  setUserEmail: (email: string) => void;
  setUserPhone: (phone: string) => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

interface ProviderProps {
  children: ReactNode;
  appId: string;
}

export const NotificationProvider: React.FC<ProviderProps> = ({ children, appId }) => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    // Set log level for debugging (remove in production)
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    // Initialize OneSignal
    OneSignal.initialize(appId);
    setIsInitialized(true);

    OneSignal.Notifications.addEventListener('permissionChange', setHasPermission);

    return () => {
      OneSignal.Notifications.removeEventListener('permissionChange', setHasPermission);
    };
  }, [appId]);

  const requestPermission = async (): Promise<boolean> => {
    const granted = await OneSignal.Notifications.requestPermission(true);
    setHasPermission(granted);
    return granted;
  };

  const setUserEmail = (email: string): void => {
    OneSignal.User.addEmail(email);
  };

  const setUserPhone = (phone: string): void => {
    OneSignal.User.addSms(phone);
  };

  return (
    <NotificationContext.Provider
      value={{ isInitialized, hasPermission, requestPermission, setUserEmail, setUserPhone }}
    >
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotifications = (): NotificationContextType => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within NotificationProvider');
  }
  return context;
};
```

### Custom Hook Pattern

```typescript
// src/hooks/useOneSignal.ts
import { useEffect, useState, useCallback } from 'react';
import { OneSignal, LogLevel } from 'react-native-onesignal';

export const useOneSignal = (appId: string) => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    // Set log level for debugging (remove in production)
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    // Initialize OneSignal
    OneSignal.initialize(appId);
    setIsInitialized(true);

    const checkPermission = async () => {
      const permission = await OneSignal.Notifications.getPermissionAsync();
      setHasPermission(permission);
    };
    checkPermission();
  }, [appId]);

  const requestPermission = useCallback(async () => {
    const granted = await OneSignal.Notifications.requestPermission(true);
    setHasPermission(granted);
    return granted;
  }, []);

  return {
    isInitialized,
    hasPermission,
    requestPermission,
  };
};
```

---

## Troubleshooting

### General Issues

| Issue | Solution |
|-------|----------|
| Module not found | Run `npm install` or `yarn install` to ensure dependencies are installed |
| Notifications not received | Verify APNs/FCM credentials in OneSignal dashboard |
| Permission always false | Check notification settings in device Settings app |
| NativeEventEmitter error | Wrap OneSignal initialization in `useEffect` hook |

### iOS Issues

| Issue | Solution |
|-------|----------|
| Pod install fails | Delete `Podfile.lock`, `Pods/` folder, and `.xcworkspace`, then run `pod install` again |
| Push capability missing | Add "Push Notifications" capability in Xcode under Signing & Capabilities |
| Background notifications fail | Enable "Remote notifications" in Background Modes capability |
| Notifications without images | Ensure Notification Service Extension is properly configured |
| App Groups mismatch | Verify same App Group ID is used for main app and NSE targets |
| Build error: PBXFileSystemSynchronizedRootGroup | Right-click the NSE folder in Xcode and select "Convert to Group" |
| Build error: Cycle Inside... | Move "Embed Foundation Extensions" build phase above "Run Script" in Build Phases |
| objectVersion 70 error | Change `objectVersion = 70;` to `objectVersion = 55;` in `project.pbxproj` |

### Android Issues

| Issue | Solution |
|-------|----------|
| Push not received | Verify `google-services.json` is in `android/app/` directory |
| FCM registration failed | Ensure Firebase project is properly configured with correct package name |
| Build fails with Gradle errors | Try `cd android && ./gradlew clean && cd ..` then rebuild |
| Notification icon issues | Create proper notification icons in all `drawable-*` folders |

### Debugging Tips

#### Enable Verbose Logging

```typescript
import { OneSignal, LogLevel } from 'react-native-onesignal';

// Add this before OneSignal.initialize()
OneSignal.Debug.setLogLevel(LogLevel.Verbose);
```

#### Check Subscription Status

```typescript
// Get the current push subscription
const subscription = OneSignal.User.pushSubscription;
console.log('Push Subscription ID:', subscription.id);
console.log('Push Token:', subscription.token);
console.log('Opted In:', subscription.optedIn);
```

#### Verify iOS Build

Build from Xcode and check the Report Navigator (Cmd + 9) for detailed error messages:

1. Open `.xcworkspace` in Xcode
2. Build the project (Cmd + B)
3. Check Report Navigator for any errors

#### Clean Build Cache

```bash
# iOS
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
npx react-native start --reset-cache

# Android
cd android && ./gradlew clean && cd ..
npx react-native start --reset-cache
```

### Common Pod Install Errors

#### CocoaPods xcodeproj gem error

If you see `ArgumentError - [Xcodeproj] Unable to find compatibility version string for object version 70`:

1. Open `ios/YourApp.xcodeproj/project.pbxproj`
2. Find `objectVersion = 70;`
3. Change to `objectVersion = 55;`
4. Run `pod install` again

#### PBXGroup Error

If you see `PBXGroup attempted to initialize an object with unknown ISA`:

1. Open Xcode
2. Find the folder mentioned in the error
3. Right-click → **Convert to Group**

### Testing Push Notifications

Push notifications only work on:
- **iOS**: Physical devices (simulators support iOS 16.2+ but with limitations)
- **Android**: Physical devices or emulators with Google Play Services

For iOS simulators running iOS 16.2+, you can use Xcode's push notification testing:
1. Build and run on simulator
2. In Xcode menu: **Features → Push Notifications**
3. Create and send a test notification
