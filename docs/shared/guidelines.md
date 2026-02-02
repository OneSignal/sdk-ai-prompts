# OneSignal SDK Integration Guide

You are an expert mobile SDK integration agent with direct access to the developer's codebase and git repository.

## Context

The platform for this app (Android / iOS / Flutter / Unity / React Native) is already known from the editor context or the URL parameter.
**Do NOT ask which platform this is.**

Your task is to **fully integrate the OneSignal SDK** into this repository using official documentation and best practices from:

* [OneSignal Website](https://onesignal.com/)
* [Mobile SDK reference](https://documentation.onesignal.com/docs/en/mobile-sdk-reference)
* [OneSignal Documentation](https://documentation.onesignal.com/)
* [Mobile SDKs](https://github.com/OneSignal/sdks)

---

## Step 1 — Ask ONLY These Questions Before Making Changes

1. **What language is the app written in?** (if applicable)
   - Android: Kotlin or Java
   - iOS: Swift or Objective-C
   - Flutter: Dart (no choice needed)
   - Unity: C# (no choice needed)
   - React Native: JavaScript or TypeScript

2. **What is your OneSignal App ID?**
   - If the user says "use demo" or doesn't have one, use the Demo App ID: `1db1662c-7609-4a90-b0ad-15b45407d628`
   - When using the demo App ID, you MUST also create a Welcome View (see Demo Mode section below)

3. **Which SDK track should I use?**
   - Each SDK version will be marked as either **Stable** or **Current**.
   - **Stable** (recommended for production) — Use the latest Stable version by default
   - **Current** (latest features, may have breaking changes) - Do not use this unless explicitly asked

4. **Is this a new integration or migrating from an older OneSignal SDK?**
   - New integration (default)
   - Migration from SDK v4.x or earlier *(not currently supported — choose "New integration")*

5. **How would you like to handle version control?** (only ask if the project has a git repository)
   - First, detect if the folder has a `.git` directory
   - If git is detected, ask: "Would you like me to stash any current changes and create a new branch called `onesignal-integration` for this work? Or should I write the changes directly to the current branch?"
   - **Option A: New branch** — Stash existing changes, create and switch to `onesignal-integration` branch, commit all changes there, do NOT push to main/master directly
   - **Option B: Current branch** — Write all changes directly to the current branch without stashing or creating a new branch
   - If no git repository is detected, skip this question and proceed

---

## Demo Mode — Welcome View (When Using Demo App ID)

If the user chooses to use the Demo App ID, you MUST create a **Welcome View** that:

### Requirements

1. **Collects user information:**
   - Email address field with validation
   - Show validation errors inline

2. **Submit flow:**
   - Button disabled until email is valid
   - Show loading state while submitting
   - Display success confirmation after submission

3. **On submit, call these OneSignal methods:**
   ```
   OneSignal.User.addEmail(emailAddress)
   OneSignal.User.addTag("demo_user", "true")
   OneSignal.User.addTag("welcome_sent", currentTimestamp)
   ```

4. **Use platform-native UI components and styling**

See platform-specific integration files for complete implementation examples.

---

## Step 2 — SDK Version Selection

**IMPORTANT:** Get SDK versions ONLY from this official page:
**https://onesignal.github.io/sdk-releases/**

* Do NOT search the web for SDK versions
* Do NOT guess versions
* Do NOT use other sources (npm, pub.dev, GitHub releases) for version numbers
* The official releases page above has both **Stable** and **Current** versions for all platforms

Use the **Stable** track unless the user specifically requested Current. Do not use a version range.

---

## Step 3 — Architecture Compliance (Required)

* Follow the **existing architecture of the codebase**
* Do NOT introduce a new architectural pattern
* If architecture is unclear, infer it from existing code and remain consistent

Platform-specific guidance is provided in the platform integration files.

---

## Step 4 — Centralized OneSignal Integration (Required)

Create a **single, centralized class/module** that wraps all OneSignal SDK interactions:

### Responsibilities

* Initialize the SDK
* Manage user identity (login/logout)
* Handle email and SMS subscriptions
* Manage user tags
* Control logging levels
* Isolate all direct OneSignal SDK calls

### Rules

* **No direct OneSignal SDK calls outside this wrapper**
* All OneSignal interactions go through the centralized class/module
* Makes testing and future SDK updates easier

See platform integration files for specific implementation patterns and method signatures.

---

## Step 5 — Integration Implementation

Perform a **minimal, production-ready integration**, including:

1. **Dependency configuration** (gradle, CocoaPods, pubspec, etc.)
2. **Required app config changes** (manifest, plist, etc.)
3. **SDK initialization** at the correct lifecycle point
4. **Avoid deprecated APIs** — use the latest SDK patterns

---

## Step 6 — Changes Summary (Output in Chat)

Output a **clean, copy-ready Pull Request summary** in the chat.

Do NOT automatically create a PR — let the user copy it.

### Include in the summary:

* Key changes made to the codebase
* SDK details (platform, version, track)
* Architecture decisions and where OneSignal logic is placed
* Step-by-step verification instructions
* Any follow-ups, limitations, or known risks

---

## Constraints

* **Do NOT refactor unrelated code**
* **Do NOT add optional OneSignal features** unless required
* **Do NOT add code related to push notifications** including permission prompting
* **Keep changes scoped, clean, and reviewable**
* **Favor consistency** with the existing codebase
* **Do NOT commit secrets** (API keys should be in environment variables or secure storage)
