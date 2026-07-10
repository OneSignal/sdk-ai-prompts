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
> - **Android: JDK 17 required** (JDK 21 also works; JDK 25+ is NOT compatible due to CMake restrictions)

---

## Environment Prerequisites (Critical)

### Android: JDK Version

**JDK 17 is required for Android builds.** JDK 25+ causes CMake configuration failures with error:
```
Execution failed for task ':app:configureCMakeDebug[arm64-v8a]'.
> WARNING: A restricted method in java.lang.System has been called
```

Before running Android builds, verify or set JAVA_HOME:
```bash
# Check current Java version
java -version

# If using JDK 25+, switch to JDK 17:
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
# Or specify path directly:
# export JAVA_HOME="/path/to/jdk-17"

npm run android
```

**Tip:** Add the JAVA_HOME export to `~/.zshrc` or `~/.bashrc` for persistence.

### iOS: CocoaPods

If `bundle install && bundle exec pod install` fails with Ruby native extension errors (common with Ruby 4.0+), use the globally installed CocoaPods instead:
```bash
# Instead of: cd ios && bundle install && bundle exec pod install
cd ios && pod install
```

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Project Requirements

- [ ] React Native 0.71 or higher
- [ ] iOS minimum deployment target is iOS 12.0 or higher
- [ ] Android `minSdkVersion` is 21 or higher
- [ ] Android `compileSdkVersion` is 33 or higher
- [ ] OneSignal App ID is available (from the user prompt)

### iOS Configuration (in Xcode)

- [ ] Push Notifications capability enabled
- [ ] Background Modes capability enabled with "Remote notifications" checked
- [ ] App Groups capability configured on BOTH the app target and `OneSignalNotificationServiceExtension`
- [ ] `OneSignalNotificationServiceExtension` target added and configured (see the Shared iOS Push Infrastructure section)
- [ ] Keep normal code signing enabled (see Shared iOS Push Infrastructure — do not pass `CODE_SIGNING_ALLOWED=NO`)
- [ ] Prefer `-scmProvider system` on CLI `xcodebuild` / SPM resolve (see Shared iOS Push Infrastructure)

### Android Configuration

- [ ] Notification icons configured (optional but recommended)

Note: Do NOT add the Google Services Gradle plugin or a `google-services.json` file for OneSignal — the SDK registers for FCM itself and these files are not required.

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

    // Do NOT request push permission here — the verification dialog
    // (see "Push Subscription Verification Dialog") requests it on tap.
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

    // Do NOT request push permission here — the verification dialog
    // (see "Push Subscription Verification Dialog") requests it on tap.
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

### 1. Google Services plugin

Do NOT add the Google Services Gradle plugin or a `google-services.json` file for OneSignal — the SDK registers for FCM itself and these files are not required.

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

**Important:** Ensure JDK 17 is set before building (JDK 25+ will fail):
```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
npx react-native run-android
```

Or build directly:

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
cd android && ./gradlew assembleDebug
```

> **Note:** You may see an AndroidManifest.xml namespace warning from the OneSignal SDK during build. This is expected and can be safely ignored.

---

## iOS Setup

Bare React Native projects have a native iOS project under `ios/`. Complete the "Shared iOS Push Infrastructure" section earlier in this document. It is required for the Notification Service Extension, App Group, Background Modes, entitlements, and Confirmed Delivery/rich notification support.

### 1. Install CocoaPods Dependencies

```bash
cd ios && pod install && cd ..
```

> **Note:** If `bundle install && bundle exec pod install` fails with Ruby native extension errors (common with Ruby 4.0+), use the global `pod install` command instead.

### 2. Add the NSE Pod Target

The shared iOS infrastructure section creates the native `OneSignalNotificationServiceExtension` target. Add a matching target block to `ios/Podfile`, then run `pod install` again:

```ruby
target 'OneSignalNotificationServiceExtension' do
  # Pin to the exact OneSignal iOS / XCFramework version selected from releases.json (same as the app) — do not use a version range.
  pod 'OneSignalXCFramework/OneSignal', 'X.Y.Z'
end
```

### 3. Build for iOS

Always build through the workspace once pods are installed:

```bash
npx react-native run-ios
```

Or open `ios/YourAppName.xcworkspace` in Xcode and build there.

---

## Push Subscription Verification Dialog

After completing SDK initialization, add a push subscription observer so the app can confirm that the device registered successfully. When the subscription ID is received, show a dialog and request push permission on tap.

### JavaScript Version

```javascript
import { Alert } from 'react-native';
import { OneSignal } from 'react-native-onesignal';

let dialogShown = false;

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
function isRegistered(subscriptionId) {
  return !!subscriptionId && !subscriptionId.startsWith('local-');
}

function maybeShowIntegrationCompleteDialog(subscriptionId) {
  if (isRegistered(subscriptionId) && !dialogShown) {
    dialogShown = true;
    showIntegrationCompleteDialog();
  }
}

function setupPushSubscriptionObserver() {
  OneSignal.User.pushSubscription.addEventListener('change', (subscription) => {
    maybeShowIntegrationCompleteDialog(subscription.current.id);
  });

  // The ID may already be assigned before the listener attaches,
  // so evaluate the current value immediately as well.
  OneSignal.User.pushSubscription.getIdAsync().then(maybeShowIntegrationCompleteDialog);
}

function showIntegrationCompleteDialog() {
  Alert.alert(
    'Your OneSignal SDK integration is complete!',
    'You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.',
    [
      {
        text: 'Got it',
        onPress: () => {
          OneSignal.Notifications.requestPermission(true);
        },
      },
    ],
    { cancelable: false }
  );
}
```

### TypeScript Version

```typescript
import { Alert } from 'react-native';
import { OneSignal } from 'react-native-onesignal';

let dialogShown = false;

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
function isRegistered(subscriptionId: string | null | undefined): boolean {
  return !!subscriptionId && !subscriptionId.startsWith('local-');
}

function maybeShowIntegrationCompleteDialog(subscriptionId: string | null | undefined): void {
  if (isRegistered(subscriptionId) && !dialogShown) {
    dialogShown = true;
    showIntegrationCompleteDialog();
  }
}

function setupPushSubscriptionObserver(): void {
  OneSignal.User.pushSubscription.addEventListener('change', (subscription) => {
    maybeShowIntegrationCompleteDialog(subscription.current.id);
  });

  // The ID may already be assigned before the listener attaches,
  // so evaluate the current value immediately as well.
  OneSignal.User.pushSubscription.getIdAsync().then(maybeShowIntegrationCompleteDialog);
}

function showIntegrationCompleteDialog(): void {
  Alert.alert(
    'Your OneSignal SDK integration is complete!',
    'You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.',
    [
      {
        text: 'Got it',
        onPress: () => {
          OneSignal.Notifications.requestPermission(true);
        },
      },
    ],
    { cancelable: false }
  );
}
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
| Notifications not received | Check App ID, notification permission, and that iOS/Android native setup completed |
| Permission always false | Check notification settings in device Settings app |
| NativeEventEmitter error | Wrap OneSignal initialization in `useEffect` hook |
| New files not showing after build | Restart Metro with cache reset: `npm start -- --reset-cache` |
| App shows old content | Kill Metro (`lsof -ti:8081 \| xargs kill -9`), restart with `--reset-cache`, rebuild |

### iOS Issues

| Issue | Solution |
|-------|----------|
| Pod install fails | Delete `Podfile.lock`, `Pods/` folder, and `.xcworkspace`, then run `pod install` again |
| Bundle install fails with Ruby errors | Skip bundler, use global CocoaPods: `cd ios && pod install` |
| Push capability missing | Add "Push Notifications" capability in Xcode under Signing & Capabilities |
| Background notifications fail | Enable "Remote notifications" in Background Modes capability |
| Notifications without images | Ensure the shared iOS Notification Service Extension setup is complete |
| App Groups mismatch | Verify same App Group ID is used for main app and NSE targets |
| No Confirmed Delivery stat | Verify NSE + App Group setup; dashboard display requires a paid OneSignal plan |
| Build error: PBXFileSystemSynchronizedRootGroup | Right-click the NSE folder in Xcode and select "Convert to Group" |
| Build error: Cycle Inside... | Move "Embed Foundation Extensions" build phase above "Run Script" in Build Phases |
| objectVersion 70 error | Change `objectVersion = 70;` to `objectVersion = 55;` in `project.pbxproj` |

### Android Issues

| Issue | Solution |
|-------|----------|
| Push not received | Check notification permission, App ID, and internet connectivity |
| Build fails with Gradle errors | Try `cd android && ./gradlew clean && cd ..` then rebuild |
| Notification icon issues | Create proper notification icons in all `drawable-*` folders |
| CMake configureCMakeDebug fails with "restricted method" | Use JDK 17 instead of JDK 25+. Set `JAVA_HOME` before building |
| AndroidManifest.xml namespace warning | This warning from the SDK is expected and can be safely ignored |
| Multiple emulators cause install confusion | Specify device: `npm run android -- --deviceId emulator-5554` |

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
