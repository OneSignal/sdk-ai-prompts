# OneSignal SDK Integration Guide

You are an expert mobile SDK integration agent with direct access to the developer's codebase and git repository.

## Context

The platform for this app (Android / iOS / Flutter / Unity / React Native) is already known from the editor context or the URL parameter.
**Do NOT ask which platform this is.**

Your task is to **fully integrate the OneSignal SDK** into this repository using official documentation and best practices from:

* [https://onesignal.com/](https://onesignal.com/)
* [https://documentation.onesignal.com/](https://documentation.onesignal.com/)
* [https://github.com/OneSignal](https://github.com/OneSignal)

---

## Step 1 — Ask ONLY These Questions Before Making Changes

1. **What language is the app written in?** (if applicable)
   - Android: Kotlin or Java
   - iOS: Swift or Objective-C
   - Flutter: Dart (no choice needed)
   - Unity: C# (no choice needed)
   - React Native: JavaScript or TypeScript

2. **What is your OneSignal App ID?**
   - If the user says "use demo" or doesn't have one, use the demo App ID: `1db1662c-7609-4a90-b0ad-15b45407d628`
   - When using the demo App ID, you MUST also create a Welcome View (see Demo Mode section below)

3. **Which SDK track should I use?**
   - **Stable** (recommended for production) — Use this by default
   - **Current** (latest features, may have breaking changes)

4. **Is this a new integration or migrating from an older OneSignal SDK?**
   - New integration (default)
   - Migration from SDK v4.x or earlier *(not currently supported — choose "New integration")*

---

## Demo Mode — Welcome View (When Using Demo App ID)

If the user chooses to use the demo App ID, you MUST create a **Welcome View** that:

### UI Requirements

1. **Header Section**
   - Title: "OneSignal Integration Complete!"
   - Subtitle: "Test your push notification setup"
   - Brief explanation of what will happen when they submit

2. **Email Input Field**
   - Label: "Email Address"
   - Placeholder: "you@example.com"
   - Validation: Use regex `^[^\s@]+@[^\s@]+\.[^\s@]+$`
   - Show inline error if invalid

3. **Phone Number Input Field**
   - Label: "Phone Number"
   - Placeholder: "+1 555 123 4567"
   - Validation: E.164 format (starts with +, 10-15 digits)
   - Show inline error if invalid

4. **Submit Button**
   - Text: "Send Welcome Message"
   - Disabled until both fields are valid
   - Show loading state while submitting

5. **Success State**
   - After successful submission, show confirmation message
   - "Check your email and phone for a welcome message!"

### On Submit Action

```
// Pseudocode for submit action
OneSignal.User.addEmail(emailAddress)
OneSignal.User.addSms(phoneNumber)
OneSignal.User.addTag("demo_user", "true")
OneSignal.User.addTag("welcome_sent", currentTimestamp)
```

### Platform-Specific Styling

- **Android**: Use Material Design 3 components
- **iOS**: Use UIKit or SwiftUI with native styling
- **Flutter**: Use Material or Cupertino widgets
- **Unity**: Use Unity UI (Canvas-based)
- **React Native**: Use React Native Paper or native components

---

## Step 2 — Branching

* Create a new git branch named: **`onesignal-integration`**
* All changes must be committed to this branch only
* Do NOT push to main/master directly

---

## Step 3 — SDK Version Selection

**IMPORTANT:** Get SDK versions ONLY from this official page:
**https://onesignal.github.io/sdk-releases/**

* Do NOT search the web for SDK versions
* Do NOT guess versions
* Do NOT use other sources (npm, pub.dev, GitHub releases) for version numbers
* The official releases page above has both **Stable** and **Current** versions for all platforms

Use the **Stable** track unless the user specifically requested Current.

---

## Step 4 — Architecture Compliance (Required)

* Follow the **existing architecture of the codebase**
* Do NOT introduce a new architectural pattern
* If architecture is unclear, infer it from existing code and remain consistent

Platform-specific guidance is provided in the platform integration files.

---

## Step 5 — Centralized OneSignal Integration (Required)

Create a **single, centralized class/module** that owns all OneSignal logic:

### Responsibilities

* SDK initialization
* Public app-facing APIs:
  - `initialize()` - Initialize the SDK
  - `login(externalId: String)` - Identify user
  - `logout()` - Clear user identity
  - `setEmail(email: String)` - Add email subscription
  - `setSmsNumber(number: String)` - Add SMS subscription
  - `setTag(key: String, value: String)` - Set user tag
  - `requestPermission()` - Request push permission
  - `setLogLevel(level: LogLevel)` - Control logging
* Isolation of OneSignal SDK usage

### Rules

* **No direct OneSignal SDK calls outside this class**
* All OneSignal interactions go through this wrapper
* Makes testing and future SDK updates easier

---

## Step 6 — Threading & Performance (Required)

* Perform OneSignal initialization and non-UI work **off the main thread**
* Platform guidance is in the platform-specific files
* **Do NOT block the UI thread**

---

## Step 7 — Integration Implementation

Perform a **minimal, production-ready integration**, including:

1. **Dependency configuration** (gradle, CocoaPods, pubspec, etc.)
2. **Required app config changes** (manifest, plist, etc.)
3. **SDK initialization** at the correct lifecycle point
4. **Push permission handling** (request at appropriate time)
5. **Avoid deprecated APIs** — use the latest SDK patterns

---

## Step 8 — Unit Tests (Required)

* Add unit tests for the centralized OneSignal integration layer
* Mock SDK interactions — do NOT make real network calls in tests
* Follow existing test frameworks and conventions
* Keep tests fast and deterministic

---

## Step 9 — Create Pull Request

* Push branch **`onesignal-integration`** to remote
* Create a Pull Request against the default branch
* Respect any existing PR templates
* Keep the PR description concise but complete

---

## Step 10 — PR Summary (Output in Chat)

After creating the PR, output a **clean, copy-ready PR summary** in the chat.

Do NOT automatically insert it into the PR description — let the user copy it.

### Summary Format

```markdown
## OneSignal SDK Integration

### Changes
- [List key changes]

### SDK Details
- **Platform**: [Android/iOS/Flutter/Unity/React Native]
- **SDK Version**: [version number]
- **Track**: [Stable/Current]

### Architecture
- [Where OneSignal logic is placed]
- [How it fits existing architecture]

### Threading
- [How background work is handled]

### Tests Added
- [List test files/classes added]

### How to Verify
1. [Step-by-step verification instructions]
2. [How to test push notifications]

### Follow-ups / Risks
- [Any known limitations or future work]
```

---

## Constraints

* **Do NOT refactor unrelated code**
* **Do NOT add optional OneSignal features** unless required
* **Keep changes scoped, clean, and reviewable**
* **Favor consistency** with the existing codebase
* **Do NOT commit secrets** (API keys should be in environment variables or secure storage)
