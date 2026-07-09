# iOS Platform Integration

## Official Documentation

* [OneSignal iOS SDK Setup](https://documentation.onesignal.com/docs/ios-sdk-setup)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-iOS-SDK)

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Xcode Capabilities

- [ ] **Push Notifications** capability enabled
  - Xcode → Target → Signing & Capabilities → + Capability → Push Notifications
- [ ] **Background Modes** capability enabled with:
  - [x] Remote notifications
  - Xcode → Target → Signing & Capabilities → + Capability → Background Modes
- [ ] **App Groups** capability enabled on BOTH the main app target and the Notification Service Extension target, with the **same** group ID (see the Notification Service Extension + App Group section)

### Notification Service Extension + App Group

- [ ] `OneSignalNotificationServiceExtension` target exists and builds
- [ ] NSE target links the `OneSignalExtension` library (SPM) or the OneSignal pod (CocoaPods)
- [ ] App Group `group.{MAIN_APP_BUNDLE_ID}.onesignal` is present in the `.entitlements` of BOTH the main app target and the NSE target
- [ ] NSE deployment target matches the main app target
- [ ] `NotificationService` forwards to `OneSignalExtension.didReceiveNotificationExtensionRequest`

### Entitlements

- [ ] `aps-environment` entitlement is present in `.entitlements` file
  ```xml
  <key>aps-environment</key>
  <string>development</string> <!-- or "production" for release -->
  ```

### Background Modes (Info.plist + pbxproj)

To enable Background Modes with Remote Notifications, you MUST make three changes:

1. **Create an `Info.plist`** file in the app source directory (if one does not already exist) with `UIBackgroundModes`:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
   	<key>UIBackgroundModes</key>
   	<array>
   		<string>remote-notification</string>
   	</array>
   </dict>
   </plist>
   ```

2. **Add both of these build settings** to the target's Debug AND Release `XCBuildConfiguration` sections in `project.pbxproj`:

   ```
   INFOPLIST_FILE = "YourApp/Info.plist";
   INFOPLIST_KEY_UIBackgroundModes = "remote-notification";
   ```

   Replace `YourApp/Info.plist` with the path to the Info.plist relative to the project root (the directory containing the `.xcodeproj`).

   Both settings are required. `INFOPLIST_FILE` points Xcode to the explicit plist so the capability appears in the Signing & Capabilities tab. `INFOPLIST_KEY_UIBackgroundModes` ensures the value is included in the generated Info.plist at build time. If the project already has `GENERATE_INFOPLIST_FILE = YES`, keep it — Xcode will merge the explicit plist with auto-generated keys.

3. **Exclude `Info.plist` from the resource copy phase** if the project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+ project format). Without this, the file sync group automatically copies `Info.plist` as a bundle resource, which conflicts with the `INFOPLIST_FILE` build setting and causes a "Multiple commands produce Info.plist" build error.

   Add a `PBXFileSystemSynchronizedBuildFileExceptionSet` section to `project.pbxproj`:

   ```
   /* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */
   		... /* PBXFileSystemSynchronizedBuildFileExceptionSet */ = {
   			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
   			membershipExceptions = (
   				Info.plist,
   			);
   			target = ... /* YourApp */;
   		};
   /* End PBXFileSystemSynchronizedBuildFileExceptionSet section */
   ```

   Then reference it from the app's `PBXFileSystemSynchronizedRootGroup` entry by adding the `exceptions` array:

   ```
   /* Begin PBXFileSystemSynchronizedRootGroup section */
   		... /* YourApp */ = {
   			isa = PBXFileSystemSynchronizedRootGroup;
   			exceptions = (
   				... /* PBXFileSystemSynchronizedBuildFileExceptionSet */,
   			);
   			path = "YourApp";
   			sourceTree = "<group>";
   		};
   ```

   This only applies to projects using file system synchronized groups. If the project uses traditional `PBXFileReference` and `PBXGroup` entries, this step is not needed.

### Info.plist (other)

- [ ] `NSAppTransportSecurity` allows HTTPS (default behavior, usually no changes needed)
- [ ] Background fetch is not blocked

### Deployment Target

- [ ] Confirm minimum deployment target is iOS 12.0 or higher (iOS 16.2+ recommended; simulator push testing requires iOS 16.2+)
- [ ] Do not change if it is already set

### APNs Configuration

- [ ] APNs Authentication Key (.p8) is uploaded to OneSignal dashboard
  - OR APNs Certificate (.p12) is uploaded
- [ ] Team ID and Key ID are configured in OneSignal dashboard

### Initialization

- [ ] OneSignal is initialized in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- [ ] For SwiftUI apps using `@main`, use `init()` or `.onAppear` in the root view

---

## Shared iOS Push Infrastructure (Required)

Complete the "Shared iOS Push Infrastructure" section earlier in this document. It is required and covers the Notification Service Extension, App Group, Background Modes, entitlements, project target wiring, dependency mapping, and verification steps.

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
└── YourApp.swift                       # @main entry point
```

---

## Threading Model (Optional)

For advanced use cases where you need explicit threading control:

### Swift (async/await)

```swift
actor OneSignalManager {
    static let shared = OneSignalManager()

    func initialize(appId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) async {
        await Task.detached(priority: .background) {
            // Set log level for debugging (remove in production)
            OneSignal.Debug.setLogLevel(.LL_VERBOSE)
            // Initialize OneSignal (launchOptions is nil outside AppDelegate)
            OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        }.value
    }

    func login(externalId: String) async {
        await Task.detached(priority: .background) {
            OneSignal.login(externalId)
        }.value
    }
}
```

### Swift (GCD)

```swift
class OneSignalManager {
    static let shared = OneSignalManager()
    private let queue = DispatchQueue(label: "com.app.onesignal", qos: .background)

    func initialize(appId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        queue.async {
            // Set log level for debugging (remove in production)
            OneSignal.Debug.setLogLevel(.LL_VERBOSE)
            // Initialize OneSignal (launchOptions is nil outside AppDelegate)
            OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        }
    }
}
```

### Objective-C

```objc
@implementation OneSignalManager

+ (instancetype)shared {
    static OneSignalManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)initializeWithAppId:(NSString *)appId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [OneSignal initialize:appId withLaunchOptions:nil];
    });
}

@end
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

### Dependency (CocoaPods)

```ruby
# Podfile
target 'YourAppName' do
  pod 'OneSignalXCFramework', '~> 5.0'
end

target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignalXCFramework', '~> 5.0'
end
```

Then run:

```bash
pod install
```

### AppDelegate (Swift)

```swift
import OneSignalFramework

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set log level for debugging (remove in production)
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        // Initialize OneSignal
        OneSignal.initialize("YOUR_ONESIGNAL_APP_ID", withLaunchOptions: launchOptions)

        return true
    }
}
```

### SwiftUI App (Swift)

```swift
import SwiftUI
import OneSignalFramework

@main
struct YourApp: App {

    init() {
        // Set log level for debugging (remove in production)
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        // Initialize OneSignal (no launchOptions in the SwiftUI lifecycle — pass nil)
        OneSignal.initialize("YOUR_ONESIGNAL_APP_ID", withLaunchOptions: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Centralized Manager (Swift)

```swift
import UIKit
import OneSignalFramework

final class OneSignalManager {
    static let shared = OneSignalManager()

    private init() {}

    func initialize(appId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        // Set log level for debugging (remove in production)
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        // Initialize OneSignal (pass launchOptions from AppDelegate; nil elsewhere)
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
    }

    func login(externalId: String) {
        OneSignal.login(externalId)
    }

    func logout() {
        OneSignal.logout()
    }

    func setEmail(_ email: String) {
        OneSignal.User.addEmail(email)
    }

    func setSmsNumber(_ number: String) {
        OneSignal.User.addSms(number)
    }

    func setTag(key: String, value: String) {
        OneSignal.User.addTag(key: key, value: value)
    }

    func setLogLevel(_ level: ONE_S_LOG_LEVEL) {
        OneSignal.Debug.setLogLevel(level)
    }
}
```

---

## Push Subscription Verification Dialog

After completing SDK initialization, add a push subscription observer so the app can confirm that the device registered successfully. When the subscription ID is received, show a dialog and request push permission on tap.

### SwiftUI

```swift
import SwiftUI
import OneSignalFramework

struct ContentView: View {
    @State private var showIntegrationCompleteAlert = false

    var body: some View {
        YourMainView()
            .onAppear {
                let observer = PushSubscriptionObserver {
                    showIntegrationCompleteAlert = true
                }
                OneSignal.User.pushSubscription.addObserver(observer)

                // The ID may already be assigned before the observer attaches,
                // so evaluate the current value immediately as well.
                observer.evaluate(OneSignal.User.pushSubscription.id)
            }
            .alert("Your OneSignal SDK integration is complete!", isPresented: $showIntegrationCompleteAlert) {
                Button("Got it") {
                    OneSignal.Notifications.requestPermission({ accepted in
                        print("User accepted notifications: \(accepted)")
                    }, fallbackToSettings: true)
                }
            } message: {
                Text("You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.")
            }
    }
}

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
private func isRegistered(_ subscriptionId: String?) -> Bool {
    guard let id = subscriptionId else { return false }
    return !id.isEmpty && !id.hasPrefix("local-")
}

class PushSubscriptionObserver: NSObject, OSPushSubscriptionObserver {
    private let onSubscribed: () -> Void
    private var hasShown = false

    init(onSubscribed: @escaping () -> Void) {
        self.onSubscribed = onSubscribed
    }

    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        evaluate(state.current.id)
    }

    // Shows the dialog exactly once, and only for a real server-assigned ID.
    func evaluate(_ subscriptionId: String?) {
        guard isRegistered(subscriptionId) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.hasShown else { return }
            self.hasShown = true
            self.onSubscribed()
        }
    }
}
```

### UIKit

```swift
import UIKit
import OneSignalFramework

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
private func isRegistered(_ subscriptionId: String?) -> Bool {
    guard let id = subscriptionId else { return false }
    return !id.isEmpty && !id.hasPrefix("local-")
}

class IntegrationCompleteObserver: NSObject, OSPushSubscriptionObserver {
    private weak var viewController: UIViewController?
    private var hasShown = false

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        evaluate(state.current.id)
    }

    // Shows the dialog exactly once, and only for a real server-assigned ID.
    func evaluate(_ subscriptionId: String?) {
        guard isRegistered(subscriptionId) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.hasShown else { return }
            self.hasShown = true
            self.showIntegrationCompleteDialog()
        }
    }

    private func showIntegrationCompleteDialog() {
        guard let viewController = viewController else { return }

        let alert = UIAlertController(
            title: "Your OneSignal SDK integration is complete!",
            message: "You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Got it", style: .default) { _ in
            OneSignal.Notifications.requestPermission({ accepted in
                print("User accepted notifications: \(accepted)")
            }, fallbackToSettings: true)
        })

        viewController.present(alert, animated: true)
    }
}

// Usage: After initializing OneSignal, register the observer and evaluate the current ID
// let observer = IntegrationCompleteObserver(viewController: self)
// OneSignal.User.pushSubscription.addObserver(observer)
// observer.evaluate(OneSignal.User.pushSubscription.id)
```

---

## Troubleshooting

| Issue                                | Solution                                                                                      |
| ------------------------------------ | --------------------------------------------------------------------------------------------- |
| Push not received                    | Verify APNs key/certificate is uploaded to OneSignal                                          |
| Background notifications fail        | Check Background Modes capability has "Remote notifications"                                  |
| Simulator issues                     | Push notifications only work on physical devices                                              |
| Entitlements error                   | Regenerate provisioning profiles in Apple Developer portal                                    |
| Push received but no image           | NSE missing or not running — verify the target exists, links `OneSignalExtension`, and its deployment target matches the app |
| No Confirmed Delivery stat           | App Group ID mismatch — must be byte-for-byte identical in both targets (also requires a paid plan) |
| Badges not updating                  | App Groups capability missing from one of the two targets                                     |
| `No such module 'OneSignalExtension'` | `OneSignalExtension` (SPM) or the OneSignal pod is not linked to the NSE target              |
| "Multiple commands produce Info.plist" (NSE) | Add the NSE `Info.plist` to the NSE sync group's `membershipExceptions` (see "Add the NSE Target to the Xcode Project" in the Shared iOS Push Infrastructure section) |
