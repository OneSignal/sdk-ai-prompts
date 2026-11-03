# React Native Expo Integration Guide

## Official Documentation

* [OneSignal Expo SDK Setup](https://documentation.onesignal.com/docs/en/react-native-expo-sdk-setup)
* [OneSignal React Native SDK Setup](https://documentation.onesignal.com/docs/react-native-sdk-setup)
* [React Native SDK API Reference](https://documentation.onesignal.com/docs/react-native-sdk-api-reference)
* [NPM Package](https://www.npmjs.com/package/react-native-onesignal)
* [GitHub Repository](https://github.com/OneSignal/react-native-onesignal)

If this file and the official [Expo SDK setup](https://documentation.onesignal.com/docs/en/react-native-expo-sdk-setup) page disagree, follow the official page.

---

## User Prompts

Ask this together with the Step 1 questions (one round):

> **Language Preference**: Do you want the integration code in JavaScript or TypeScript?

If the project already uses TypeScript (`tsconfig.json`, `.tsx` files), don't ask; use TypeScript.

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
- [ ] iOS deployment target 15.0+ (official guide). If the project sets `iPhoneDeploymentTarget`, it must be 15.0 or higher.

### Android Firebase Configuration

Follow **Android Firebase Configuration** in the shared guidelines (rules, the Step 1 question, and handling the answer). Expo specifics, from the official [Expo SDK setup](https://documentation.onesignal.com/docs/en/react-native-expo-sdk-setup) and [Android Firebase credentials](https://documentation.onesignal.com/docs/en/android-firebase-credentials) pages:

- [ ] Expected location: any path in the project (for example the project root), referenced by `android.googleServicesFile` in the app config. Takes effect from `react-native-onesignal` 5.5.16.
  ```json
  {
    "expo": {
      "android": {
        "package": "com.example.app",
        "googleServicesFile": "./google-services.json"
      }
    }
  }
  ```
- [ ] The file's client entry matches `android.package`, and every package variant you build. Otherwise prebuild fails with `No matching client found for package name`.
- [ ] Don't apply the Google Services plugin yourself: `npx expo prebuild` copies the file and applies it.
- [ ] Requires a development build (`npx expo run:android`). Expo Go is not supported.

### Initialization

- [ ] OneSignal initialized inside a `useEffect` in the root component (`App.tsx` / `App.js`, or `app/_layout.tsx` for Expo Router), as in the official setup guide
- [ ] Push permission requested right after initialization with `requestPermission(false)`

### Notification Icons (Android, Recommended)

- [ ] Recommend in the summary adding a small icon through the plugin's `smallIcons` option (named `ic_stat_onesignal_default`). Without it, notifications show a default bell icon. Guide: https://documentation.onesignal.com/docs/en/notification-icons. Don't generate icons unless asked.

---

## Installation

Install the Expo plugin at its Current version (releases.json entry for Expo) and `react-native-onesignal` at the React Native Current version, with the project's package manager:

```bash
npx expo install onesignal-expo-plugin@X.Y.Z
npm install --save react-native-onesignal@A.B.C
```

`react-native-onesignal` must be 5.5.16 or later for google-services.json to take effect.

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

### Centralized Service (src/services/oneSignalService.ts)

Wraps every OneSignal call. Initialization only: no login, email, SMS, or tag methods (see **Scope: initialization only** in the shared guidelines). For JavaScript, drop the type annotations and use `.js`.

```typescript
import { OneSignal, LogLevel } from 'react-native-onesignal';

// The App ID from Step 1, or the YOUR_APP_ID placeholder if it was skipped.
const ONESIGNAL_APP_ID = 'YOUR_APP_ID';

let isInitialized = false;

export const OneSignalService = {
  initialize(): void {
    if (isInitialized) return;
    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize(ONESIGNAL_APP_ID);
    isInitialized = true;
  },

  /** false = don't fall back to Settings, as in the official guide. */
  requestPushPermission(): void {
    OneSignal.Notifications.requestPermission(false);
  },

  setLogLevel(level: LogLevel): void {
    OneSignal.Debug.setLogLevel(level);
  },
};
```

### Root Component

Follows the official setup guide: initialize and request permission in a `useEffect` in the root component. Use `App.tsx` / `App.js` for traditional Expo apps, or `app/_layout.tsx` / `app/_layout.js` for Expo Router. The App ID lives only in the service. Keep the component's existing content; only add the effect.

```typescript
import React, { useEffect } from 'react';
import { Stack } from 'expo-router'; // Expo Router only
import { OneSignalService } from '../src/services/oneSignalService';

export default function RootLayout() {
  useEffect(() => {
    OneSignalService.initialize();
    // In production, consider an in-app message instead for better opt-in rates.
    OneSignalService.requestPushPermission();
  }, []);

  return <Stack />; // or the app's existing content
}
```

The official guide's snippet also adds `click` and `foregroundWillDisplay` listeners. They aren't needed for setup; mention them in the summary as an optional next step.

---

## Verification

Give the developer these steps in the Changes Summary, following the official guide:

1. Build a development build (`npx expo run:ios` / `npx expo run:android`, or EAS Build) and launch it. Not Expo Go. The permission prompt appears at launch.
2. Before accepting, open **Audience → Users & subscriptions → Subscriptions** in the OneSignal dashboard. The new Subscription shows **Never Subscribed**.
3. Tap **Allow** on the prompt.
4. Refresh the dashboard. The status changes to **Subscribed**.
5. Send a test push. This needs FCM credentials (Android) and APNs credentials (iOS) in the OneSignal dashboard.

Do **not** reinstall or wipe the app just to re-check; that creates a second OneSignal subscription.

---

## After Setup: Push Credentials in OneSignal

In the Changes Summary, for each platform selected in Step 1:

- **Android:** use the shared **After setup: FCM credentials in OneSignal** note.
- **iOS:** > **Push won't reach iOS devices until your OneSignal app has APNs credentials.** In OneSignal, go to **Settings → Push & In-App → Apple iOS (APNs)** and add your p8 Auth Key (recommended) or p12 Certificate.

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
| Notifications not received | Check App ID, notification permission, and that a development build (not Expo Go) was used |
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
