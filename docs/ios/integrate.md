# iOS Platform Integration

## Official Documentation

* [OneSignal iOS SDK Setup](https://documentation.onesignal.com/docs/en/ios-sdk-setup)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-iOS-SDK)

If this file and the official [iOS SDK setup](https://documentation.onesignal.com/docs/en/ios-sdk-setup) page disagree, follow the official page.

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following. For NSE, App Groups, entitlements, Background Modes, and embedding the extension, complete and use the checklist in the **Shared iOS Push Infrastructure** section earlier in this document — do not re-implement those steps here.

### Xcode / project

- [ ] Shared iOS Push Infrastructure required outcomes are all satisfied (NSE, App Group, entitlements, Background Modes, embed phase)
- [ ] Push Notifications capability is enabled on the main app target (via entitlements / Signing & Capabilities)
- [ ] Minimum deployment target is iOS 15.0 or higher (iOS 16.2+ recommended), per the official setup guide; do not lower an existing higher target
- [ ] `NSAppTransportSecurity` allows HTTPS (default; usually no changes)
- [ ] Signed app entitlements verified (`codesign -d --entitlements -` shows `aps-environment` + App Group); do not disable code signing on CLI builds

### Initialization

- [ ] OneSignal is initialized in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`, as in the official setup guide
- [ ] SwiftUI apps (`@main struct ... : App`) add an `AppDelegate` with `@UIApplicationDelegateAdaptor` and initialize there. Don't initialize in a view's `init()` or `.onAppear`.
- [ ] Initialize on the main thread, directly in `didFinishLaunchingWithOptions`. Don't move it to a background queue or `Task`.
- [ ] Push permission is requested right after initialization (see **Push Permission Request**)

### Notification Icons

iOS uses the app icon for notifications; no extra step.

---

## Shared iOS Push Infrastructure (Required)

Complete the "Shared iOS Push Infrastructure" section earlier in this document. It is the single source of truth for the Notification Service Extension, App Group, Background Modes, entitlements, project target wiring, dependency mapping, and verification steps.

Do NOT skip that section. It is part of the minimal iOS integration because Confirmed Delivery, rich notifications, action buttons, and badges depend on it.

---

## Architecture Guidance

### MVVM

```
YourApp/
├── Services/
│   └── OneSignalManager.swift          # OneSignal wrapper
├── ViewModels/
│   └── ...
├── Views/
│   └── ...
└── AppDelegate.swift                   # Initialize here
```

Do NOT name the wrapper class `NotificationService` — that name is reserved for the class inside the Notification Service Extension target.

### MVC

```
YourApp/
├── Services/
│   └── OneSignalManager.swift
├── Controllers/
│   └── ...
└── AppDelegate.swift
```

### SwiftUI App Lifecycle

```
YourApp/
├── Services/
│   └── OneSignalManager.swift
├── Views/
│   └── ...
└── YourApp.swift                       # @main entry point + AppDelegate adaptor
```

---

## Code Examples

### Dependency (Swift Package Manager)

Use the XCFramework-based package for smaller downloads:

1. In Xcode: File → Add Packages → Enter URL:
   ```
   https://github.com/OneSignal/OneSignal-XCFramework
   ```
2. Add these libraries to your **app target**:
   - `OneSignalFramework`
   - `OneSignalInAppMessages`
   - `OneSignalLocation`
3. Add this library to the **OneSignalNotificationServiceExtension target**:
   - `OneSignalExtension`

Most common mistake: products attached to the wrong target. `OneSignalFramework` goes on the app target only; `OneSignalExtension` goes on the NSE target only.

When resolving or building **Swift Package Manager** packages from the CLI, pass `-scmProvider system` on `xcodebuild` so package resolution does not prompt for the login keychain password (see Shared iOS Push Infrastructure). Skip this for CocoaPods-only projects.

### Dependency (CocoaPods)

Requires CocoaPods 1.16.2+. Use the official guide's Podfile and version range exactly:

```ruby
# Podfile
# If platform is uncommented, set to the same value as your minimum deployments target in Xcode
# platform :ios, '15.0'

target 'YourAppName' do
  pod 'OneSignal/OneSignal', '>= 5.2.9', '< 6.0'
  pod 'OneSignal/OneSignalInAppMessages', '>= 5.2.9', '< 6.0'
  pod 'OneSignal/OneSignalLocation', '>= 5.2.9', '< 6.0' # Optional
end

target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignal/OneSignal', '>= 5.2.9', '< 6.0'
end
```

Then run:

```bash
pod install
```

Report the resolved version from `Podfile.lock` in the summary.

### Centralized Manager (Swift)

Wraps every OneSignal call. Initialization only: no login, email, SMS, or tag methods (see **Scope: initialization only** in the shared guidelines).

```swift
import UIKit
import OneSignalFramework

final class OneSignalManager {
    static let shared = OneSignalManager()

    private init() {}

    /// Call from application(_:didFinishLaunchingWithOptions:), before any other OneSignal call.
    func initialize(appId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Enable verbose logging to debug issues (remove in production)
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
    }

    /// fallbackToSettings: false, as in the official guide.
    func requestPushPermission() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: false)
    }

    func setLogLevel(_ level: ONE_S_LOG_LEVEL) {
        OneSignal.Debug.setLogLevel(level)
    }
}
```

### SwiftUI App (Swift)

Following the official setup guide, add an `AppDelegate` through `@UIApplicationDelegateAdaptor`. Replace `YOUR_APP_ID` with the App ID from Step 1.

```swift
import SwiftUI

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        OneSignalManager.shared.initialize(appId: "YOUR_APP_ID", launchOptions: launchOptions)
        OneSignalManager.shared.requestPushPermission()
        return true
    }
}
```

### AppDelegate (UIKit)

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        OneSignalManager.shared.initialize(appId: "YOUR_APP_ID", launchOptions: launchOptions)
        OneSignalManager.shared.requestPushPermission()
        return true
    }
}
```

### Objective-C

```objc
#import <OneSignalFramework/OneSignalFramework.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Enable verbose logging to debug issues (remove in production)
    [OneSignal.Debug setLogLevel:ONE_S_LL_VERBOSE];
    [OneSignal initialize:@"YOUR_APP_ID" withLaunchOptions:launchOptions];

    // fallbackToSettings:false, as in the official guide
    [OneSignal.Notifications requestPermission:^(BOOL accepted) {
        NSLog(@"User accepted notifications: %d", accepted);
    } fallbackToSettings:false];

    return YES;
}
```

In Objective-C projects, keep these calls in a single wrapper class (for example `OneSignalManager`) and call it from the app delegate.

---

## Push Permission Request

Follow the official setup guide: request push permission in `didFinishLaunchingWithOptions`, right after initialization, through the wrapper, with `fallbackToSettings: false`. Don't add a verification dialog, and don't request permission anywhere else.

In the Changes Summary, mention the official guide's advice: in production, consider prompting with an in-app message instead, for better opt-in rates.

If the developer skipped the App ID, still add the permission request, and include this alert at the top of the Changes Summary, next to the App ID reminder:

> **The app will show the push permission prompt at launch, but the device won't register with OneSignal until you set your App ID.** Users who accept now won't be reachable until a build with your real App ID ships.

---

## Verification

Give the developer these steps in the Changes Summary, following the official guide:

1. Build and launch the app on a device (or an iOS 16.2+ Simulator on Apple Silicon).
2. In the OneSignal dashboard, open **Audience → Users & subscriptions → Subscriptions**. The new Subscription shows **Never Subscribed**.
3. Accept the permission prompt in the app.
4. Refresh the dashboard. The status changes to **Subscribed**.
5. Send a test push. This needs APNs credentials in the OneSignal dashboard (see **After Setup: APNs Credentials in OneSignal**).

Do **not** erase the Simulator or uninstall/reinstall just to re-check — that creates a second OneSignal subscription. See shared guidelines: **Verification without duplicate subscriptions**.

---

## After Setup: APNs Credentials in OneSignal

Once the SDK is set up in the app, tell the developer in the Changes Summary (don't ask about it in Step 1):

> **Push won't reach iOS devices until your OneSignal app has APNs credentials.** In OneSignal, go to **Settings → Push & In-App → Apple iOS (APNs)** and add your p8 Auth Key (recommended) or p12 Certificate. Guide: https://documentation.onesignal.com/docs/en/ios-sdk-setup

---

## Troubleshooting

For NSE, App Group, `OneSignalExtension` module, Info.plist sync-group, and signing/entitlements issues, use the **iOS Infrastructure Troubleshooting** table in the Shared iOS Push Infrastructure section.

| Issue                         | Solution                                                                 |
| ----------------------------- | ------------------------------------------------------------------------ |
| Push not received             | Check notification permission and APNs credentials in OneSignal; confirm signed entitlements include `aps-environment` (see shared section) |
| Background notifications fail | Check Background Modes includes Remote notifications (see shared section) |
| Permission prompt never appears | Confirm `requestPushPermission()` runs right after `initialize` in `didFinishLaunchingWithOptions`. If the user already answered, iOS won't prompt again |
| Simulator / APNs              | Build/launch and the permission prompt work in Simulator. On Apple Silicon Macs, Simulator can receive real sandbox APNs pushes; use a physical device if background/lock-screen display is flaky or you are not on Apple Silicon |
| Entitlements / signing error  | Regenerate provisioning profiles; confirm `DEVELOPMENT_TEAM` and App Group; do not disable code signing |
