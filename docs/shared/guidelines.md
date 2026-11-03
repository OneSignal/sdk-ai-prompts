# OneSignal SDK Integration Guide

You are an expert SDK integration agent with direct access to the developer's codebase and git repository.

## Context

The platform for this app (Android / iOS / Flutter / Unity / React Native / Web) is already known from the editor context or the URL parameter.
**Do NOT ask which platform this is.**

Your task is to **fully integrate the OneSignal SDK** into this repository using official documentation and best practices from:

* [OneSignal Website](https://onesignal.com/)
* [Mobile SDK reference](https://documentation.onesignal.com/docs/en/mobile-sdk-reference)
* [Web SDK setup](https://documentation.onesignal.com/docs/web-sdk-setup)
* [OneSignal Documentation](https://documentation.onesignal.com/)
* [OneSignal SDKs](https://github.com/OneSignal/sdks)

---

## App ID

The App ID is usually provided in the user's prompt — the same message that linked you to this file. Use **that** App ID for all OneSignal SDK initialization and any REST calls in the verification scaffolding.

If no App ID is present in the user's prompt, ask for it in Step 1, together with any other questions. Ask it as an open text question, not multiple choice. Only use buttons if an option can hold typed text, labeled **Here it is: [App ID]** and **Skip for now**.

> **What's your OneSignal App ID?**
> Find it in the OneSignal dashboard under **Settings → Keys & IDs** ([guide](https://documentation.onesignal.com/docs/en/keys-and-ids)).
>
> * **Here it is:** paste your App ID as your reply
> * **Skip for now:** reply "skip". No users or devices will register with OneSignal until you add it.

Handling the answer:

* **App ID provided:** an App ID is a UUID (for example `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`). If the value doesn't look like one, it is probably a REST API key or an Organization key. Ask again, and don't put API keys in the app.
* **Skipped:** complete the integration with a single, clearly named placeholder (`YOUR_APP_ID`, as in the official docs) defined in one place, inside the centralized OneSignal wrapper. Tell the user the device won't register with OneSignal until a real App ID is set. Start the Changes Summary with this follow-up and name the file and line to update.

**Never** invent, hardcode, or reuse a demo or fallback App ID.

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
   - Web: JavaScript or TypeScript (and detect the framework — plain HTML/JS, React, Next.js, Vue, Angular, Svelte, etc.)

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

4. **What's your OneSignal App ID?** (only if it wasn't in the user's prompt; see **App ID** above for the exact wording)

5. **Is there a `google-services.json`?** (only when the integration builds for Android and the file isn't detected; see **Android Firebase Configuration** below for the wording)

6. **Platform-specific questions** from the platform integration file, if any

Ask all applicable questions together in one round, not one at a time. If any question needs typed text (such as the App ID) and your tool can't attach text to an option, ask the whole round as a chat message so the user can answer everything in one reply.

### Bundle ID and application ID (Required)

* **Use the iOS bundle identifier and Android applicationId / package name already defined in the project.** Do not invent, rename, or "improve" them (including swapping to example or OneSignal-owned IDs) unless the user explicitly asks.
* Derive the default App Group from the existing main-app bundle ID: `group.{MAIN_APP_BUNDLE_ID}.onesignal`. If the project already defines a custom App Group for OneSignal, keep it and set `OneSignal_app_groups_key` as documented in the iOS push infrastructure section.
* If a required identifier is missing or clearly unusable for the selected platform(s), stop and ask the user to set a real value in the project, then continue. Do not proceed by making one up.

### Package manager continuity (Required)

* Detect the project's existing dependency managers and **keep using them**.
* iOS: preserve CocoaPods vs Swift Package Manager. Do not migrate the app between them unless the user asks.
* JavaScript apps: use the lockfile's package manager (npm / yarn / pnpm / bun).
* Do **not** add an NSE-only CocoaPods `Podfile` to an SPM-based iOS/Flutter project. Follow the platform section for how to link the Notification Service Extension under the detected manager.

---

## Push Permission Request (Required)

Request push permission **exactly where and how the platform integration file says**. Each platform file follows its official setup guide:

* **Mobile (Android, iOS, Flutter, React Native, Expo, Unity):** request permission at launch, right after initialization, through the wrapper, with the call the official guide uses. Don't add a verification dialog or any other custom UI.
* **Web:** don't request permission in code. The official guide configures the permission prompt in the OneSignal dashboard (see the Web integration file).
* In the Changes Summary, mention the official guides' advice: in production, consider prompting with an in-app message instead, for better opt-in rates.
* **If the App ID was skipped** (mobile; Web has its own alert in the Web file), still add the permission request, and put this alert at the top of the Changes Summary, next to the App ID reminder:
  > **The app will show the push permission prompt at launch, but the device won't register with OneSignal until you set your App ID.** Users who accept now won't be reachable until a build with your real App ID ships.

### Verification without duplicate subscriptions

When building, launching, or re-checking the integration:

* **Do NOT** clear app data, wipe the emulator/simulator, or uninstall/reinstall the app solely to re-verify setup.
* Clearing storage / reinstalling resets the install identity. The platform then mints a new push token and OneSignal creates a **new** subscription, leaving the previous one orphaned — so the dashboard shows duplicates for the same test flow.
* Prefer a normal rebuild + relaunch (or install over the existing app) that **preserves** app storage.
* One successful server-assigned subscription is enough. Do not deliberately create a second subscription to prove the integration works.

---

## Android Firebase Configuration (All Platforms That Build for Android)

On the Current SDK versions, the official docs recommend adding the app's own Firebase configuration for every platform that builds for Android. Treat it as part of the integration, not an optional feature. The platform integration file says where the file goes and how the build processes it. Reference: https://documentation.onesignal.com/docs/en/android-firebase-credentials

Skip this section for iOS-only and Web integrations, and for cross-platform projects where the developer didn't select Android.

### Rules

* **Never create, generate, or edit `google-services.json`.** It comes from the developer's Firebase project.
* Its `package_name` must match the app's Android package name (`applicationId`, or `android.package` on Expo).
* It must come from the **same Firebase project** as the FCM Service Account uploaded to OneSignal. Compare `project_info.project_id` in the file with the Firebase Project ID in the OneSignal dashboard. A mismatch causes subscription status `-6`.
* Complete the platform's processing step. Without it the file does nothing, and the build gives no warning.
* After building, confirm the file took effect as the platform file describes. A successful build alone doesn't prove it.
* Don't add Firebase SDKs (Analytics, Crashlytics, etc.) or call `FirebaseMessaging` APIs for OneSignal. OneSignal owns the push token lifecycle.

### If the file is not detected

Ask during Step 1, together with the other questions. Fill in the app's real Android package name. Use a multiple-choice question if your tool supports it:

> **I couldn't find a `google-services.json` file in your project.**
> OneSignal recommends adding it for Android. Download it from the **same Firebase project** you use to generate the FCM Service Account file for OneSignal, check that its package name is `{package name}`, and place it in `{expected location}`. How to get both files: https://documentation.onesignal.com/docs/en/android-firebase-credentials
>
> * **I've added it, check again**
> * **Skip for now.** I understand that adding it later may affect push delivery for my existing Android users.

Handling the answer:

* **"I've added it":** check the expected location again and confirm the `package_name` matches. If it is still missing or doesn't match, say what you found and ask again.
* **Found in the wrong place:** if a `google-services.json` with a matching `package_name` is elsewhere in the project, or at a path the developer mentions, tell the developer where you found it and add this option to the question:
  * **Copy it from there** (`{path}`)

  On that answer, copy the file to the expected location unchanged and confirm the `package_name` matches. Don't search outside the project unless the developer points you to a location.
* **Skipped:** don't add the file or its build step. Finish the integration and list the Firebase configuration as a follow-up in the Changes Summary, with the link above.
* **Skipped, and Firebase Installation ID registration is on** (the merged manifest has `firebase_messaging_installation_id_enabled` set to boolean `true`): tell the user plainly that push won't work on Android (subscription status `-32`) until the Firebase configuration is added. Start the Changes Summary with this; don't present it as an optional follow-up.

### After setup: FCM credentials in OneSignal

Once the SDK is set up in the app, tell the developer in the Changes Summary (don't ask about it in Step 1):

> **Push won't reach Android devices until your OneSignal app has FCM credentials.** In OneSignal, go to **Settings → Push & In-App → Google Android (FCM)** and upload your Firebase Service Account JSON. It should come from the same Firebase project as your `google-services.json`. Guide: https://documentation.onesignal.com/docs/en/android-firebase-credentials

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

Always use the **Current** track (`channels.current.version`). Do not use Stable unless the user specifically asks for it.

Write the dependency the way the platform integration file says, which follows the official setup guide. Where it gives a range (for example Android `[5.6.1, 5.99.99]` or CocoaPods `'>= 5.2.9', '< 6.0'`), copy the range exactly and make sure the Current version falls inside it. Where it gives no range, use the Current version (npm exact version, pub caret `^X.Y.Z`, SPM "Up to Next Major Version" from X.Y.Z). Don't invent or widen ranges. Report the resolved version in the Changes Summary.

When using the JSON source, read the exact version from:
`<sdk entry>.channels.<track>.version`

Find the SDK entry by matching the requested platform against the entry's `name` or `displayName`. For example, for iOS, find the entry with `name: "iOS"` and use `channels.current.version`. Do not infer the version from the newest tag, GitHub release order, GitHub `prerelease` status, or semantic-version sorting.

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
* Request push permission (see **Push Permission Request**)
* Control logging levels
* Isolate all direct OneSignal SDK calls

### Scope: initialization only

Follow the official setup guide, which covers installing and initializing the SDK. **Do NOT add login/logout, External ID, email, SMS, or tag calls**, even if the app has a login screen or collects emails. If a platform file shows them for reference, don't implement them.

In the Changes Summary, recommend the next step from the official docs: assign an External ID with `OneSignal.login("user_id")` when users sign in, so their subscriptions are unified across devices. Link the platform's SDK setup guide.

### Rules

* **No direct OneSignal SDK calls outside this wrapper**
* All OneSignal interactions go through the centralized class/module
* Official-guide snippets call the SDK directly; when you copy them, route those calls through the wrapper
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
* Step-by-step verification instructions (simulator is fine for build/launch and the permission prompt; on Apple Silicon, sandbox APNs in Simulator is also valid — see Shared iOS Push Infrastructure)
* Any follow-ups, limitations, or known risks relevant to the code changes made

---

## Constraints

* **Do NOT refactor unrelated code**
* **Do NOT add optional OneSignal features** unless required. Anything the platform integration file marks as **Required** (e.g. the iOS Notification Service Extension and App Group) is part of the core integration — NOT an optional feature — and MUST be implemented
* **Do NOT add push-notification features beyond SDK initialization, the push permission request, and the sections the platform integration file marks as Required.** Request push permission **only** where the platform integration file says (see **Push Permission Request**): at launch on mobile, and through the dashboard-configured prompt on web. Don't request it anywhere else.
* **Do NOT clear app data, wipe the emulator/simulator, or uninstall/reinstall solely to re-verify** — that creates duplicate OneSignal subscriptions (see Verification without duplicate subscriptions)
* **Keep changes scoped, clean, and reviewable**
* **Favor consistency** with the existing codebase
* **Do NOT commit secrets** (API keys should be in environment variables or secure storage)
