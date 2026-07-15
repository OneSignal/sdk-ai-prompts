# iOS Platform Integration

## Official Documentation

* [OneSignal iOS SDK Setup](https://documentation.onesignal.com/docs/ios-sdk-setup)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-iOS-SDK)

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following. For NSE, App Groups, entitlements, Background Modes, and embedding the extension, complete and use the checklist in the **Shared iOS Push Infrastructure** section earlier in this document — do not re-implement those steps here.

### Xcode / project

- [ ] Shared iOS Push Infrastructure required outcomes are all satisfied (NSE, App Group, entitlements, Background Modes, embed phase)
- [ ] Push Notifications capability is enabled on the main app target (via entitlements / Signing & Capabilities)
- [ ] Minimum deployment target is iOS 12.0 or higher (iOS 16.2+ recommended); do not lower an existing higher target
- [ ] `NSAppTransportSecurity` allows HTTPS (default; usually no changes)
- [ ] Signed app entitlements verified (`codesign -d --entitlements -` shows `aps-environment` + App Group); do not disable code signing on CLI builds

### Initialization

- [ ] OneSignal is initialized in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- [ ] For SwiftUI apps using `@main`, use `init()` or `.onAppear` in the root view

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
  # Pin to the exact OneSignal iOS / XCFramework version selected from releases.json (same as the app) — do not use a version range.
  pod 'OneSignalXCFramework/OneSignal', 'X.Y.Z'
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

OneSignal stores push subscription observers weakly. Retain the observer in `@State` (or equivalent) for the view's lifetime — a local `let` inside `.onAppear` is deallocated immediately and the dialog never appears.

```swift
import SwiftUI
import OneSignalFramework

struct ContentView: View {
    @State private var showIntegrationCompleteAlert = false
    @State private var pushObserver: PushSubscriptionObserver?

    var body: some View {
        YourMainView()
            .onAppear {
                let observer = PushSubscriptionObserver {
                    showIntegrationCompleteAlert = true
                }
                pushObserver = observer
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

// Usage: store the observer as a view-controller property (OneSignal retains observers weakly).
// After initializing OneSignal:
// self.integrationCompleteObserver = IntegrationCompleteObserver(viewController: self)
// OneSignal.User.pushSubscription.addObserver(self.integrationCompleteObserver!)
// self.integrationCompleteObserver?.evaluate(OneSignal.User.pushSubscription.id)
```

---

## Troubleshooting

For NSE, App Group, `OneSignalExtension` module, Info.plist sync-group, and signing/entitlements issues, use the **iOS Infrastructure Troubleshooting** table in the Shared iOS Push Infrastructure section.

| Issue                         | Solution                                                                 |
| ----------------------------- | ------------------------------------------------------------------------ |
| Push not received             | Check notification permission; confirm signed entitlements include `aps-environment` (see shared section) |
| Background notifications fail | Check Background Modes includes Remote notifications (see shared section) |
| Verification dialog never appears | Retain the push subscription observer (weakly held by the SDK); evaluate the current ID immediately |
| Simulator issues              | Simulator is fine for build/launch and the verification dialog; full APNs delivery may still need a device |
| Entitlements / signing error  | Regenerate provisioning profiles; confirm `DEVELOPMENT_TEAM` and App Group; do not disable code signing |
