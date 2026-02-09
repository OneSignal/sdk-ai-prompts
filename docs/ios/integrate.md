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

### Entitlements

- [ ] `aps-environment` entitlement is present in `.entitlements` file
  ```xml
  <key>aps-environment</key>
  <string>development</string> <!-- or "production" for release -->
  ```

### Info.plist (if needed)

- [ ] `NSAppTransportSecurity` allows HTTPS (default behavior, usually no changes needed)
- [ ] Background fetch is not blocked

### Deployment Target

- [ ] Confirm minimum deployment target is iOS 12.0 or higher (iOS 14+ recommended)
- [ ] Do not change if it is already set

### APNs Configuration

- [ ] APNs Authentication Key (.p8) is uploaded to OneSignal dashboard
  - OR APNs Certificate (.p12) is uploaded
- [ ] Team ID and Key ID are configured in OneSignal dashboard

### Initialization

- [ ] OneSignal is initialized in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- [ ] For SwiftUI apps using `@main`, use `init()` or `.onAppear` in the root view

---

## Architecture Guidance

### MVVM

```
YourApp/
├── Services/
│   └── NotificationService.swift      # OneSignal wrapper
├── ViewModels/
│   └── ...
├── Views/
│   └── ...
└── AppDelegate.swift                   # Initialize here
```

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

    func initialize(appId: String) async {
        await Task.detached(priority: .background) {
            // Set log level for debugging (remove in production)
            OneSignal.Debug.setLogLevel(.LL_VERBOSE)
            // Initialize OneSignal
            OneSignal.initialize("YOUR_ONESIGNAL_APP_ID", withLaunchOptions: launchOptions)
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

    func initialize(appId: String) {
        queue.async {
            // Set log level for debugging (remove in production)
            OneSignal.Debug.setLogLevel(.LL_VERBOSE)
            // Initialize OneSignal
            OneSignal.initialize("YOUR_ONESIGNAL_APP_ID", withLaunchOptions: launchOptions)
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

Add to Xcode: File → Add Packages → Enter URL:
```
https://github.com/OneSignal/OneSignal-iOS-SDK
```

### Dependency (CocoaPods)

```ruby
# Podfile
pod 'OneSignalXCFramework', '~> 5.0'
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
        // Initialize OneSignal
        OneSignal.initialize("YOUR_ONESIGNAL_APP_ID", withLaunchOptions: launchOptions)
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
import OneSignalFramework

final class OneSignalManager {
    static let shared = OneSignalManager()

    private init() {}

    func initialize(appId: String) {
        // Set log level for debugging (remove in production)
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        // Initialize OneSignal
        OneSignal.initialize("YOUR_ONESIGNAL_APP_ID", withLaunchOptions: launchOptions)
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

## Push Subscription Observer + Welcome Dialog

After completing the integration, add a push subscription observer that shows a dialog when the device receives a push subscription ID.

### SwiftUI

```swift
import SwiftUI
import OneSignalFramework

struct ContentView: View {
    @State private var showWelcomeAlert = false

    var body: some View {
        YourMainView()
            .onAppear {
                OneSignal.User.pushSubscription.addObserver(PushSubscriptionObserver {
                    showWelcomeAlert = true
                })
            }
            .alert("Your OneSignal integration is complete!", isPresented: $showWelcomeAlert) {
                Button("Trigger your first journey") {
                    OneSignal.InAppMessages.addTrigger("ai_implementation_campaign_email_journey", withValue: "true")
                }
            } message: {
                Text("Click the button below to trigger your first journey via an in-app message.")
            }
    }
}

class PushSubscriptionObserver: NSObject, OSPushSubscriptionObserver {
    private let onSubscribed: () -> Void

    init(onSubscribed: @escaping () -> Void) {
        self.onSubscribed = onSubscribed
    }

    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        let previousId = state.previous.id
        let currentId = state.current.id

        if (previousId == nil || previousId?.isEmpty == true) && currentId != nil && !currentId!.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.onSubscribed()
            }
        }
    }
}
```

### UIKit

```swift
import UIKit
import OneSignalFramework

class WelcomeDialogObserver: NSObject, OSPushSubscriptionObserver {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        let previousId = state.previous.id
        let currentId = state.current.id

        if (previousId == nil || previousId?.isEmpty == true) && currentId != nil && !currentId!.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showWelcomeDialog()
            }
        }
    }

    private func showWelcomeDialog() {
        guard let viewController = viewController else { return }

        let alert = UIAlertController(
            title: "Your OneSignal integration is complete!",
            message: "Click the button below to trigger your first journey via an in-app message.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Trigger your first journey", style: .default) { _ in
            OneSignal.InAppMessages.addTrigger("ai_implementation_campaign_email_journey", withValue: "true")
        })

        viewController.present(alert, animated: true)
    }
}

// Usage: After initializing OneSignal, register the observer
// let observer = WelcomeDialogObserver(viewController: self)
// OneSignal.User.pushSubscription.addObserver(observer)
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Push not received | Verify APNs key/certificate is uploaded to OneSignal |
| Background notifications fail | Check Background Modes capability has "Remote notifications" |
| Simulator issues | Push notifications only work on physical devices |
| Entitlements error | Regenerate provisioning profiles in Apple Developer portal |
