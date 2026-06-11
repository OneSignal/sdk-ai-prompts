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

## App ID

The App ID is provided in the user's prompt — the same message that linked you to this file. Use **that** App ID for all OneSignal SDK initialization and any REST calls in the verification scaffolding.

If no App ID is present in the user's prompt, ask the user to provide one before proceeding. **Never** hardcode a demo or fallback App ID.

---

## Step 1 — Ask ONLY These Questions Before Making Changes

1. **What language is the app written in?** (if applicable)
   - Android: Kotlin or Java
   - iOS: Swift or Objective-C
   - Flutter: Dart (no choice needed)
   - Unity: C# (no choice needed)
   - React Native: JavaScript or TypeScript

2. **How would you like to handle version control?** (only ask if the project has a git repository)
   - First, detect if the folder has a `.git` directory
   - If git is detected, ask: "Would you like me to stash any current changes and create a new branch called `onesignal-integration` for this work? Or should I write the changes directly to the current branch?"
   - **Option A: New branch** — Stash existing changes, create and switch to `onesignal-integration` branch, commit all changes there, do NOT push to main/master directly
   - **Option B: Current branch** — Write all changes directly to the current branch without stashing or creating a new branch
   - If no git repository is detected, skip this question and proceed

---

## Push Subscription Verification Dialog (Required)

After completing SDK initialization, add a push subscription observer so the app can confirm that the device registered successfully.

### Requirements (All Platforms)

1. **Register a push subscription observer** immediately after OneSignal is initialized.

2. **Treat the device as registered only when the push subscription ID is a real, server-assigned value** — non-empty and **not** prefixed with `local-`. The SDK assigns a `local-` placeholder ID during initialization (before the device registers with OneSignal's servers); that placeholder does **not** mean the device is registered.

3. **Evaluate the current subscription ID both on change and immediately at observer-registration time.** The ID may already be server-assigned before your observer attaches, so reacting only to the change event can miss the transition and the dialog would never appear.

4. **When a real subscription ID is present, show a platform-native dialog/alert exactly once** (guard with a "shown once" flag) with:
   - **Title:** "Your OneSignal SDK integration is complete!"
   - **Message:** "You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications."
   - **Single button:** **"Got it"**

5. **On button tap**, request push permission.

See platform-specific integration files for implementation examples.

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
* **Do NOT add push-notification features beyond SDK initialization and the Push Subscription Verification Dialog.** The dialog's on-tap permission request (Step 5 of the verification requirements) is required and is the **only** place push permission may be requested — do NOT prompt for permission at app launch or anywhere else
* **Keep changes scoped, clean, and reviewable**
* **Favor consistency** with the existing codebase
* **Do NOT commit secrets** (API keys should be in environment variables or secure storage)
