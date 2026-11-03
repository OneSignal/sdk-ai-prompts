# React Native Integration Guide

## Official Documentation

* [OneSignal React Native SDK Setup](https://documentation.onesignal.com/docs/en/react-native-sdk-setup)
* [React Native SDK API Reference](https://documentation.onesignal.com/docs/react-native-sdk-api-reference)
* [NPM Package](https://www.npmjs.com/package/react-native-onesignal)
* [GitHub Repository](https://github.com/OneSignal/react-native-onesignal)

If this file and the official [React Native SDK setup](https://documentation.onesignal.com/docs/en/react-native-sdk-setup) page disagree, follow the official page.

---

## User Prompts

Ask this together with the Step 1 questions (one round):

> **Language Preference**: Do you want the integration code in JavaScript or TypeScript?

If the project already uses TypeScript (`tsconfig.json`, `App.tsx`), don't ask; use TypeScript.

---

## Important: Bare React Native Workflow

> **This guide is for bare React Native projects** (created with `npx @react-native-community/cli init`).
>
> For Expo projects, use the [Expo SDK Setup](../react-native-expo/ai-prompt.md) instead.
>
> **Requirements (official guide):**
> - React Native 0.79+ with the New Architecture enabled
> - iOS: macOS with Xcode 14+, CocoaPods 1.16.2+, device with iOS 15+ or Simulator with iOS 16.2+
> - Android: Android 7.0+ device or emulator with Google Play Services
> - **Android: JDK 17 required** (JDK 21 also works; JDK 25+ is NOT compatible due to CMake restrictions)
>
> If the project is below React Native 0.79 or has the New Architecture disabled, report it in the summary; don't upgrade React Native.

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
java -version
# If using JDK 25+, switch to JDK 17:
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
npm run android
```

### iOS: CocoaPods

If `bundle install && bundle exec pod install` fails with Ruby native extension errors (common with Ruby 4.0+), use the globally installed CocoaPods instead:
```bash
cd ios && pod install
```

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Project Requirements

- [ ] React Native 0.79 or higher, New Architecture enabled
- [ ] iOS minimum deployment target is iOS 15.0 or higher on the app and the NSE
- [ ] Don't change the Android Gradle Plugin version. If the build reports an incompatible AGP, recommend updating Android Studio (or ask before lowering AGP).

### iOS Configuration (in Xcode)

- [ ] Push Notifications capability enabled
- [ ] Background Modes capability enabled with "Remote notifications" checked
- [ ] App Groups capability configured on BOTH the app target and `OneSignalNotificationServiceExtension`
- [ ] `OneSignalNotificationServiceExtension` target added and configured (see the Shared iOS Push Infrastructure section)
- [ ] Keep normal code signing enabled (see Shared iOS Push Infrastructure — do not pass `CODE_SIGNING_ALLOWED=NO`)

### Android Configuration

- [ ] Android Firebase configuration added (see **1. Google Services plugin** below)
- [ ] Notification icons recommended in the summary (see **2. Notification icons**)

### Initialization

- [ ] OneSignal initialized inside a `useEffect` in the root component (`App.tsx` / `App.js`), as in the official setup guide. Not at module top level (causes `NativeEventEmitter` errors).
- [ ] Push permission requested right after initialization with `requestPermission(false)`

---

## Installation

Install the Current version from releases.json (Step 2) with the project's package manager:

```bash
npm install --save react-native-onesignal@X.Y.Z
# or
yarn add react-native-onesignal@X.Y.Z
```

React Native autolinking handles native linking.

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

### Root Component (App.tsx / App.js)

Follows the official setup guide: initialize and request permission in a `useEffect`. The App ID lives only in the service. Keep the component's existing content; only add the effect.

```typescript
import React, { useEffect } from 'react';
import { OneSignalService } from './src/services/oneSignalService';

export default function App() {
  useEffect(() => {
    OneSignalService.initialize();
    // In production, consider an in-app message instead for better opt-in rates.
    OneSignalService.requestPushPermission();
  }, []);

  // ...existing app content
}
```

The official guide's snippet also adds `click` and `foregroundWillDisplay` listeners. They aren't needed for setup; mention them in the summary as an optional next step.

---

## Android Setup

### 1. Google Services plugin

Follow **Android Firebase Configuration** in the shared guidelines (rules, the Step 1 question, and handling the answer). React Native specifics, from the official [React Native SDK setup](https://documentation.onesignal.com/docs/en/react-native-sdk-setup) and [Android Firebase credentials](https://documentation.onesignal.com/docs/en/android-firebase-credentials) pages:

- Expected location: `android/app/google-services.json`. Requires `react-native-onesignal` 5.5.16 or later.
- If the app already uses React Native Firebase, the plugin is already in place: only add the file.
- Otherwise, declare the plugin in `android/build.gradle`:
  ```groovy
  buildscript {
      dependencies {
          classpath 'com.google.gms:google-services:[4.4.2, 4.99.99]'
      }
  }
  ```
- Apply it at the bottom of `android/app/build.gradle`:
  ```groovy
  apply plugin: 'com.google.gms.google-services'
  ```
  **This step is required.** Without it the file does nothing, and the build gives no warning.
- Only apply the plugin once the file is present; otherwise the build fails.
- Confirm the file took effect: from `android/`, run `./gradlew :app:processDebugGoogleServices`, then check that `google_app_id` and `project_id` appear under `android/app/build/generated/res/`.

### 2. Notification icons

Recommend in the summary adding a small icon named `ic_stat_onesignal_default` under `android/app/src/main/res/drawable-*`. Without it, notifications show a default bell icon. Guide: https://documentation.onesignal.com/docs/en/notification-icons. Don't generate icons unless asked.

### 3. Build for Android

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
cd android && ./gradlew assembleDebug
```

> **Note:** You may see an AndroidManifest.xml namespace warning from the OneSignal SDK during build. This is expected and can be safely ignored.

---

## iOS Setup

Bare React Native projects have a native iOS project under `ios/`. Complete the "Shared iOS Push Infrastructure" section earlier in this document. It is required for the Notification Service Extension, App Group, Background Modes, entitlements, and Confirmed Delivery/rich notification support.

### 1. Add the NSE Pod Target

Add this block to `ios/Podfile`, after the app target:

```ruby
target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignalXCFramework', '>= 5.0.0', '< 6.0'
end
```

The NSE must request the same `OneSignalXCFramework` subspecs as `react-native-onesignal`'s podspec, or Xcode fails with `Multiple commands produce '.../XCFrameworkIntermediates/OneSignalXCFramework/...'`. By default the podspec uses the aggregate pod, as above. With `ONESIGNAL_DISABLE_LOCATION=true`, list `OneSignalXCFramework/OneSignal` and `OneSignalXCFramework/OneSignalInAppMessages` instead (see the shared **CocoaPods projects — Podfile block**).

### 2. Install pods and build

```bash
cd ios && pod install && cd ..
npx react-native run-ios
```

Or open `ios/YourAppName.xcworkspace` in Xcode and build there.

---

## Verification

Give the developer these steps in the Changes Summary, following the official guide:

1. Launch the app on a device or emulator. If you test on an Android emulator, cold-boot it first. The permission prompt appears at launch.
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

### General Issues

| Issue | Solution |
|-------|----------|
| Module not found | Run `npm install` or `yarn install` to ensure dependencies are installed |
| Permission prompt never appears | Confirm `requestPushPermission()` runs after `initialize` in the root `useEffect`. If the user already answered, the OS won't prompt again |
| NativeEventEmitter error | Move OneSignal initialization inside `useEffect` |
| New files not showing after build | Restart Metro with cache reset: `npm start -- --reset-cache` |

### iOS Issues

| Issue | Solution |
|-------|----------|
| Pod install fails | Delete `Podfile.lock`, `Pods/` folder, and `.xcworkspace`, then run `pod install` again |
| `Multiple commands produce '.../XCFrameworkIntermediates/OneSignalXCFramework/...'` | The NSE and the app request different `OneSignalXCFramework` subspecs. Make the NSE block match the podspec (see **1. Add the NSE Pod Target**), then `pod install` |
| Bundle install fails with Ruby errors | Skip bundler, use global CocoaPods: `cd ios && pod install` |
| Notifications without images | Ensure the shared iOS Notification Service Extension setup is complete |
| No Confirmed Delivery stat | Verify NSE + App Group setup; dashboard display requires a paid OneSignal plan |
| Build error: PBXFileSystemSynchronizedRootGroup | Right-click the NSE folder in Xcode and select "Convert to Group" |
| Build error: Cycle Inside... | Move "Embed Foundation Extensions" build phase above "Run Script" in Build Phases |
| objectVersion 70 error | Change `objectVersion = 70;` to `objectVersion = 55;` in `project.pbxproj` |

### Android Issues

| Issue | Solution |
|-------|----------|
| Build fails with Gradle errors | Try `cd android && ./gradlew clean && cd ..` then rebuild |
| Incompatible AGP version | Update Android Studio; ask before lowering AGP |
| CMake configureCMakeDebug fails with "restricted method" | Use JDK 17 instead of JDK 25+. Set `JAVA_HOME` before building |
| Subscription status -32 or -33 | google-services.json missing, or from a different Firebase project than the FCM Service Account in OneSignal |
| AndroidManifest.xml namespace warning | This warning from the SDK is expected and can be safely ignored |
