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

## Step 1 — Detect First, Then Ask ONLY What Is Unknown

Before editing files, inspect the repository and record a short readiness picture. Prefer detection over questions. If an answer is already clear from the user's request, the repo, or the execution context, do NOT ask — proceed and state the assumption in your summary.

### Detect-first checklist (run before changes)

Inspect the project and note:

* Existing OneSignal usage (dependencies, init calls, wrappers)
* iOS bundle identifier(s) and Android applicationId / package name as defined in the project today
* iOS dependency manager in use: CocoaPods (`Podfile` / `Pods` / Pods xcconfig includes) vs Swift Package Manager (no Podfile or SPM-enabled Flutter/iOS setup, package references)
* JS package manager when relevant (npm / yarn / pnpm / bun) from the lockfile
* Existing push setup: Notification Service Extension, App Groups, Push / Background Modes capabilities, notification permission prompts
* Signing clues on iOS targets (`DEVELOPMENT_TEAM`, `CODE_SIGN_STYLE`, entitlements files)

### Questions to ask only when unknown

1. **What language is the app written in?** (if applicable)
   - Android: Kotlin or Java
   - iOS: Swift or Objective-C
   - Flutter: Dart (no choice needed)
   - Unity: C# (no choice needed)
   - React Native / Expo: JavaScript or TypeScript

2. **Which mobile platforms should this integration cover?** (cross-platform SDKs only: Flutter, React Native, Expo, Unity)
   - Ask: **iOS**, **Android**, or **both**
   - Do **not** offer a code-only / skip-native option
   - Native iOS and native Android prompts skip this question — the platform is already known
   - Apply shared SDK / wrapper work once; apply native iOS or Android project work only for the selected platform(s)
   - In the final summary, report status per selected platform (shared code, iOS native, Android native)

3. **How would you like to handle version control?** (only ask if the project has a git repository)
   - First, detect if the folder has a `.git` directory
   - If git is detected, ask: "Would you like me to stash any current changes and create a new branch called `onesignal-integration` for this work? Or should I write the changes directly to the current branch?"
   - **Option A: New branch** — Stash existing changes, create and switch to `onesignal-integration` branch, commit all changes there, do NOT push to main/master directly
   - **Option B: Current branch** — Write all changes directly to the current branch without stashing or creating a new branch
   - If no git repository is detected, skip this question and proceed

### Bundle ID and application ID (Required)

* **Use the iOS bundle identifier and Android applicationId / package name already defined in the project.** Do not invent, rename, or "improve" them (including swapping to example or OneSignal-owned IDs) unless the user explicitly asks.
* Derive the default App Group from the existing main-app bundle ID: `group.{MAIN_APP_BUNDLE_ID}.onesignal`. If the project already defines a custom App Group for OneSignal, keep it and set `OneSignal_app_groups_key` as documented in the iOS push infrastructure section.
* If a required identifier is missing or clearly unusable for the selected platform(s), stop and ask the user to set a real value in the project, then continue. Do not proceed by making one up.

### Package manager continuity (Required)

* Detect the project's existing dependency managers and **keep using them**.
* iOS: preserve CocoaPods vs Swift Package Manager. Do not migrate the app between them unless the user asks.
* JavaScript apps: use the lockfile's package manager (npm / yarn / pnpm / bun).
* Do **not** add an NSE-only CocoaPods `Podfile` to an SPM-based iOS/Flutter project. Follow the platform section for how to link the Notification Service Extension under the detected manager.

### Dashboard credentials

* Do **not** instruct the user to upload APNs keys (`.p8`) or FCM credentials as part of this integration, and do not treat those uploads as agent tasks.
* If push fails after a correct project integration, troubleshooting may note that dashboard credentials must match this app — but credential upload is out of scope for the agent workflow.

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

**IMPORTANT:** Get SDK versions ONLY from this official JSON endpoint:
**https://onesignal.github.io/sdk-releases/releases.json**

* Do NOT use the human-readable releases page for version selection
* Do NOT search the web for SDK versions
* Do NOT guess versions
* Do NOT use other sources (npm, pub.dev, GitHub releases) for version numbers
* The official JSON endpoint above has both **Stable** and **Current** versions for all platforms
* iOS note: `OneSignal-XCFramework` (the SPM repo) shares version tags with `OneSignal-iOS-SDK` — the same version number applies to both

Use the **Stable** track unless the user specifically requested Current. Pin the selected version exactly (e.g. SPM `exactVersion`, exact npm/pub version) — do NOT invent version ranges. Exception: where a platform integration file shows a dependency line with an official constraint (e.g. the CocoaPods `pod 'OneSignalXCFramework', '~> 5.0'` blocks), use that constraint as written.

When using the JSON source, read the exact version from:
`<sdk entry>.channels.<track>.version`

Find the SDK entry by matching the requested platform against the entry's `name` or `displayName`. For example, for iOS Stable, find the entry with `name: "iOS"` and use `channels.stable.version`. Do not infer the Stable version from the newest tag, GitHub release order, GitHub `prerelease` status, or semantic-version sorting.

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
* Some platform-file code examples (e.g. the Push Subscription Verification Dialog) show direct SDK calls for brevity — when implementing them, route those calls through the wrapper
* Makes testing and future SDK updates easier

See platform integration files for specific implementation patterns and method signatures.

---

## Step 5 — Integration Implementation

Perform a **minimal, production-ready integration**, including:

1. **Dependency configuration** (gradle, CocoaPods, pubspec, etc.)
2. **Required app config changes** (manifest, plist, etc.)
3. **Required notification infrastructure** — everything the platform integration file marks as **Required** (e.g. on iOS: the Notification Service Extension target and App Group). "Minimal" means no optional extras — it does **NOT** mean skipping required platform setup
4. **SDK initialization** at the correct lifecycle point
5. **Avoid deprecated APIs** — use the latest SDK patterns

---

## Step 6 — Changes Summary (Output in Chat)

Output a **clean, copy-ready Pull Request summary** in the chat.

Do NOT automatically create a PR — let the user copy it.

### Include in the summary:

* Key changes made to the codebase
* SDK details (platform, version, track)
* Architecture decisions and where OneSignal logic is placed
* For cross-platform SDKs: which mobile platforms were selected and status for each (shared code, iOS native, Android native)
* Bundle ID / applicationId used from the project (do not invent new ones in the summary either)
* Step-by-step verification instructions (simulator is fine for build/launch and the verification dialog path)
* Any follow-ups, limitations, or known risks — do **not** list APNs `.p8` or FCM credential upload as remaining agent/user setup steps for this flow

---

## Constraints

* **Do NOT refactor unrelated code**
* **Do NOT add optional OneSignal features** unless required. Anything the platform integration file marks as **Required** (e.g. the iOS Notification Service Extension and App Group) is part of the core integration — NOT an optional feature — and MUST be implemented
* **Do NOT add push-notification features beyond SDK initialization, the Push Subscription Verification Dialog, and the sections the platform integration file marks as Required.** The dialog's on-tap permission request (Step 5 of the verification requirements) is required and is the **only** place push permission may be requested — do NOT prompt for permission at app launch or anywhere else
* **Keep changes scoped, clean, and reviewable**
* **Favor consistency** with the existing codebase
* **Do NOT commit secrets** (API keys should be in environment variables or secure storage)
