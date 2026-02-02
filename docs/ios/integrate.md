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

## Demo Welcome View (SwiftUI)

When using the demo App ID, create this view:

### WelcomeView.swift

```swift
import SwiftUI
import OneSignalFramework

struct WelcomeView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private var isEmailValid: Bool {
        let regex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    private var isFormValid: Bool {
        isEmailValid
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if showSuccess {
                    successView
                } else {
                    formView
                }
            }
            .padding()
            .navigationTitle("OneSignal Demo")
        }
    }

    private var formView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("OneSignal Integration Complete!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter your details to receive a welcome message")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("Email Address", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                if !email.isEmpty && !isEmailValid {
                    Text("Invalid email address")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(action: submitForm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send Welcome Message")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isFormValid || isLoading)

            Spacer()
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Success!")
                .font(.title)
                .fontWeight(.bold)

            Text("Check your email for a welcome message!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func submitForm() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .background).async {
            OneSignal.User.addEmail(email)
            OneSignal.User.addTag(key: "demo_user", value: "true")
            OneSignal.User.addTag(key: "welcome_sent", value: "\(Date().timeIntervalSince1970)")

            DispatchQueue.main.async {
                isLoading = false
                showSuccess = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
```

### UIKit Version (WelcomeViewController.swift)

```swift
import UIKit
import OneSignalFramework

class WelcomeViewController: UIViewController {

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let emailTextField = UITextField()
    private let submitButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let successView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        // Title
        titleLabel.text = "OneSignal Integration Complete!"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Enter your details to receive a welcome message"
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stackView.addArrangedSubview(subtitleLabel)

        // Email field
        emailTextField.placeholder = "Email Address"
        emailTextField.borderStyle = .roundedRect
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        stackView.addArrangedSubview(emailTextField)

        // Submit button
        submitButton.setTitle("Send Welcome Message", for: .normal)
        submitButton.backgroundColor = .systemGray
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.isEnabled = false
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        stackView.addArrangedSubview(submitButton)
    }

    @objc private func textFieldDidChange() {
        let isValid = isEmailValid
        submitButton.isEnabled = isValid
        submitButton.backgroundColor = isValid ? .systemBlue : .systemGray
    }

    private var isEmailValid: Bool {
        guard let email = emailTextField.text else { return false }
        let regex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    @objc private func submitTapped() {
        guard let email = emailTextField.text else { return }

        submitButton.isEnabled = false
        activityIndicator.startAnimating()

        DispatchQueue.global(qos: .background).async {
            OneSignal.User.addEmail(email)
            OneSignal.User.addTag(key: "demo_user", value: "true")
            OneSignal.User.addTag(key: "welcome_sent", value: "\(Date().timeIntervalSince1970)")

            DispatchQueue.main.async { [weak self] in
                self?.showSuccess()
            }
        }
    }

    private func showSuccess() {
        // Replace form with success message
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .systemGreen
        checkmark.contentMode = .scaleAspectFit
        checkmark.heightAnchor.constraint(equalToConstant: 64).isActive = true
        stackView.addArrangedSubview(checkmark)

        let successLabel = UILabel()
        successLabel.text = "Success!"
        successLabel.font = .preferredFont(forTextStyle: .title1)
        successLabel.textAlignment = .center
        stackView.addArrangedSubview(successLabel)

        let messageLabel = UILabel()
        messageLabel.text = "Check your email for a welcome message!"
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        stackView.addArrangedSubview(messageLabel)
    }
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Push not received | Verify APNs key/certificate is uploaded to OneSignal |
| Background notifications fail | Check Background Modes capability has "Remote notifications" |
| Simulator issues | Push notifications only work on physical devices |
| Entitlements error | Regenerate provisioning profiles in Apple Developer portal |
