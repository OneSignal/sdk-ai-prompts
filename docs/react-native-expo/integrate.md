# React Native Expo Integration Guide

## Official Documentation

* [OneSignal Expo SDK Setup](https://documentation.onesignal.com/docs/en/react-native-expo-sdk-setup)
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

## Important: Development Build Required

> **Push notifications do NOT work in Expo Go.**
>
> This guide is for **managed Expo apps** using `onesignal-expo-plugin`. Bare React Native apps should use the React Native prompt instead.
>
> You must create a development build or EAS Build to test push notifications:
> ```bash
> npx expo prebuild
> npx expo run:ios    # for iOS
> npx expo run:android # for Android
> ```
>
> Alternatively, use [EAS Build](https://docs.expo.dev/build/introduction/) for cloud-based builds.

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Expo Configuration

- [ ] Expo SDK 53+ (React Native 0.79+) with New Architecture enabled
- [ ] `bundleIdentifier` set in `app.json` under `expo.ios`
- [ ] `package` set in `app.json` under `expo.android`
- [ ] `ios.infoPlist.UIBackgroundModes` includes `remote-notification`
- [ ] `ios.entitlements["aps-environment"]` is set to `development` or `production`
- [ ] `onesignal-expo-plugin` is the **first** item in the `plugins` array
- [ ] Development build created (not using Expo Go)
- [ ] For iOS builds, the plugin is allowed to add the Notification Service Extension (`disableNSE` is not `true`)

### OneSignal Dashboard

- [ ] OneSignal App ID obtained from dashboard
- [ ] iOS: APNs key/certificate uploaded to OneSignal dashboard
- [ ] Android: FCM credentials configured (Firebase Service Account JSON)

Note: The OneSignal SDK handles FCM registration itself. Do NOT add `expo.android.googleServicesFile` or a `google-services.json` file for OneSignal — they are not required. Push credentials (the Firebase Service Account JSON) are configured in the OneSignal dashboard, not in the app.

### Initialization

- [ ] OneSignal initialized in `App.js` or `App.tsx` (root component)
- [ ] Initialize before rendering main app content

---

## Installation

Install the OneSignal SDK and Expo plugin:

```bash
npx expo install onesignal-expo-plugin
npm install --save react-native-onesignal
```

Or with Yarn:

```bash
npx expo install onesignal-expo-plugin
yarn add react-native-onesignal
```

---

## Expo Configuration

Configure OneSignal in `app.json`, `app.config.js`, or `app.config.ts`.

### app.json

The OneSignal plugin MUST be the first item in the `plugins` array. This prevents the `OneSignal/OneSignal.h file not found` build error.

```json
{
  "expo": {
    "name": "YourAppName",
    "slug": "your-app-slug",
    "ios": {
      "bundleIdentifier": "com.yourcompany.yourapp",
      "infoPlist": {
        "UIBackgroundModes": ["remote-notification"]
      },
      "entitlements": {
        "aps-environment": "development"
      },
      "appleTeamId": "YOUR_APPLE_TEAM_ID"
    },
    "android": {
      "package": "com.yourcompany.yourapp"
    },
    "plugins": [
      [
        "onesignal-expo-plugin",
        {
          "mode": "development"
        }
      ]
    ]
  }
}
```

Use `mode: "development"` for local/dev builds and `mode: "production"` for TestFlight and App Store builds. `ios.entitlements["aps-environment"]` should match that mode.

### app.config.ts

Starting in `onesignal-expo-plugin` 2.6.0, you can import `withOneSignal` for typed plugin configuration:

```typescript
import { ConfigContext, ExpoConfig } from '@expo/config';
import withOneSignal from 'onesignal-expo-plugin/plugin';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  ios: {
    ...config.ios,
    bundleIdentifier: 'com.yourcompany.yourapp',
    appleTeamId: 'YOUR_APPLE_TEAM_ID',
    infoPlist: {
      ...config.ios?.infoPlist,
      UIBackgroundModes: ['remote-notification'],
    },
    entitlements: {
      ...config.ios?.entitlements,
      'aps-environment': 'development',
    },
  },
  android: {
    ...config.android,
    package: 'com.yourcompany.yourapp',
  },
  plugins: [
    withOneSignal({
      mode: 'development',
    }),
    ...(config.plugins ?? []),
  ],
});
```

### Plugin Options

| Option | Required | Description |
|--------|----------|-------------|
| `mode` | ✅ | Configures the APNs environment entitlement. Use `"development"` for testing and `"production"` for TestFlight/App Store builds |
| `devTeam` | Deprecated | Prefer `ios.appleTeamId` in Expo config. The plugin falls back to `devTeam` only if `appleTeamId` is missing |
| `iPhoneDeploymentTarget` | No | iOS deployment target used when adding the Notification Service Extension. Match the minimum iOS version in the Podfile |
| `smallIcons` | No | Android small notification icon paths (white transparent PNG, 96x96px), auto-scaled into resource folders |
| `largeIcons` | No | Android large notification icon paths (256x256px) |
| `smallIconAccentColor` | No | Android notification icon accent color, e.g. `"#FF0000"` |
| `iosNSEFilePath` | No | Local path to a custom Objective-C Notification Service Extension file, e.g. `"./assets/NotificationService.m"` |
| `appGroupName` | No | Custom iOS App Group name. Defaults to `group.{ios.bundleIdentifier}.onesignal` if omitted |
| `nseBundleIdentifier` | No | Suffix for the NSE bundle ID. Defaults to `OneSignalNotificationServiceExtension` |
| `disableNSE` | No | If `true`, the iOS NSE is not added. The NSE is required for badges, confirmed receipt, media attachments, and action buttons — only disable if the app intentionally needs basic push only |
| `disableLocation` | No | If `true`, excludes the native OneSignal location module from iOS and Android. Requires `react-native-onesignal` 5.5.1+ |

### Example with Android icons and location disabled

```json
{
  "plugins": [
    [
      "onesignal-expo-plugin",
      {
        "mode": "development",
        "disableLocation": true,
        "smallIcons": ["./assets/ic_stat_onesignal_default.png"],
        "largeIcons": ["./assets/ic_onesignal_large_icon_default.png"],
        "smallIconAccentColor": "#FF0000"
      }
    ]
  ]
}
```

---

## iOS Native Push Infrastructure (Expo Plugin Managed)

Expo uses `onesignal-expo-plugin` to generate the native iOS Notification Service Extension and App Group configuration. Do NOT start by manually creating an NSE target in Xcode for managed Expo apps. Configure the plugin first, then run prebuild/development build and inspect the generated native project only as a verification step.

```bash
npx expo prebuild
npx expo run:ios
```

Do not claim iOS rich notifications or Confirmed Delivery are complete until the generated native project has:

* Main app entitlements with `aps-environment` and `group.{BUNDLE_IDENTIFIER}.onesignal`
* `OneSignalNotificationServiceExtension` target
* NSE entitlements with the exact same App Group
* `OneSignalExtension` linked to the NSE target
* The NSE `.appex` embedded in the main app

If these are missing, first verify:

* `onesignal-expo-plugin` is first in the `plugins` array
* `disableNSE` is not `true`
* `ios.bundleIdentifier` is set
* `ios.infoPlist.UIBackgroundModes` includes `remote-notification`
* `ios.entitlements["aps-environment"]` is set

Only use manual native edits as a fallback for generated projects where the plugin cannot express a required custom setup. For custom Objective-C NSE code, prefer the plugin's `iosNSEFilePath` option.

---

## SDK Initialization

Initialize OneSignal in the root of the app. Use `App.tsx` / `App.js` for traditional Expo apps, or `app/_layout.tsx` / `app/_layout.js` for Expo Router.

Do NOT request push permission during initialization. The verification dialog below requests permission when the user taps **Got it**.

### Traditional App Entry

```javascript
import React, { useEffect } from 'react';
import { View, Text } from 'react-native';
import { OneSignal, LogLevel } from 'react-native-onesignal';

const ONESIGNAL_APP_ID = 'YOUR_ONESIGNAL_APP_ID';

export default function App() {
  useEffect(() => {
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize(ONESIGNAL_APP_ID);

    const clickListener = (event) => {
      console.log('OneSignal: notification clicked:', event);
    };

    const foregroundListener = (event) => {
      console.log('OneSignal: foreground will display:', event);
    };

    OneSignal.Notifications.addEventListener('click', clickListener);
    OneSignal.Notifications.addEventListener('foregroundWillDisplay', foregroundListener);

    return () => {
      OneSignal.Notifications.removeEventListener('click', clickListener);
      OneSignal.Notifications.removeEventListener('foregroundWillDisplay', foregroundListener);
    };
  }, []);

  return (
    <View>
      <Text>Your App Content</Text>
    </View>
  );
}
```

### Expo Router

```javascript
import React, { useEffect } from 'react';
import { Stack } from 'expo-router';
import { OneSignal, LogLevel } from 'react-native-onesignal';

const ONESIGNAL_APP_ID = 'YOUR_ONESIGNAL_APP_ID';

export default function RootLayout() {
  useEffect(() => {
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize(ONESIGNAL_APP_ID);

    const clickListener = (event) => {
      console.log('OneSignal: notification clicked:', event);
    };

    const foregroundListener = (event) => {
      console.log('OneSignal: foreground will display:', event);
    };

    OneSignal.Notifications.addEventListener('click', clickListener);
    OneSignal.Notifications.addEventListener('foregroundWillDisplay', foregroundListener);

    return () => {
      OneSignal.Notifications.removeEventListener('click', clickListener);
      OneSignal.Notifications.removeEventListener('foregroundWillDisplay', foregroundListener);
    };
  }, []);

  return <Stack />;
}
```

If a listener needs access to props or state, define it with `useCallback` so the same function reference is used for both `addEventListener` and `removeEventListener`.

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

| Issue | Solution |
|-------|----------|
| Push notifications not working in Expo Go | Expo Go does not support push notifications. Create a development build with `npx expo prebuild` and `npx expo run:ios` or `npx expo run:android` |
| Missing `bundleIdentifier` error | Add `"bundleIdentifier": "com.yourcompany.yourapp"` under `expo.ios` in `app.json` |
| Missing `package` error | Add `"package": "com.yourcompany.yourapp"` under `expo.android` in `app.json` |
| iOS build fails with pod errors | Run `npx expo prebuild --clean` to regenerate native projects |
| iOS push received but no image | Verify the generated native project has the shared iOS Notification Service Extension and App Group setup |
| No Confirmed Delivery stat | Verify NSE + App Group setup; dashboard display requires a paid OneSignal plan |
| Android build fails with Gradle errors | Ensure Java 17 is installed: `export JAVA_HOME="/path/to/java17"` then rebuild |
| AssetCatalogSimulatorAgent failure (Xcode 16.1) | Simplify asset catalog or restart Mac. See workaround below. |
| Build shows "0 errors" but fails | Capture stderr: `npx expo run:ios 2> error-logs.txt` and inspect the file |
| Notifications not received | Verify APNs/FCM credentials in OneSignal dashboard |
| Permission always false | Check notification settings in device Settings app |
| Module not found | Clear Metro cache: `npx expo start --clear` |

### AssetCatalogSimulatorAgent Workaround (Xcode 16.1)

If you encounter `Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn`, try this workaround:

```bash
# Backup original asset catalog
cp -r ios/[AppName]/Images.xcassets ios/[AppName]/Images.xcassets.backup

# Create minimal asset catalog
rm -rf ios/[AppName]/Images.xcassets
mkdir -p ios/[AppName]/Images.xcassets/AppIcon.appiconset

# Create minimal Contents.json
echo '{"info":{"author":"xcode","version":1}}' > ios/[AppName]/Images.xcassets/Contents.json
echo '{"images":[],"info":{"author":"xcode","version":1}}' > ios/[AppName]/Images.xcassets/AppIcon.appiconset/Contents.json

# Rebuild
npx expo run:ios
```

### Debugging Build Failures

```bash
# Capture full error output
npx expo run:ios 2> error-logs.txt

# Search for actual errors
grep -i "error:" error-logs.txt

# Or check Expo's xcodebuild log
cat .expo/xcodebuild.log | grep -A5 "error:"
```
