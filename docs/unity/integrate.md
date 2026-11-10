# Unity Platform Integration

## Official Documentation

* [OneSignal Unity SDK Setup](https://documentation.onesignal.com/docs/en/unity-sdk-setup)
* [Unity SDK API Reference](https://documentation.onesignal.com/docs/unity-sdk-api-reference)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-Unity-SDK)

If this file and the official [Unity SDK setup](https://documentation.onesignal.com/docs/en/unity-sdk-setup) page disagree, follow the official page.

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Unity Configuration

- [ ] Unity 2022.3 or newer (official guide). If the project is older, report it in the summary; don't upgrade it.

### Package Installation

- [ ] OneSignal Unity SDK installed through the npmjs scoped registry (see **Installation**) or the Unity Asset Store
- [ ] An External Dependency Manager present. The OneSignal UPM packages don't depend on one (see **Install External Dependency Manager**)
- [ ] `Assets/OneSignal/link.xml` present (see **OneSignal SDK Setup window steps**), so IL2CPP code stripping doesn't remove the SDK's platform classes

### Android Build Settings

Apply these yourself from files where a recipe is given; list the rest in the summary as developer steps.

- [ ] **Custom Main Gradle Template** and **Custom Gradle Properties Template** enabled (Player Settings ▸ Android ▸ Publishing Settings). From files: copy `mainTemplate.gradle` and `gradleTemplate.properties` from the Unity install's `PlaybackEngines/AndroidPlayer/Tools/GradleTemplates/` into `Assets/Plugins/Android/` (skip any that already exist), and set `useCustomMainGradleTemplate: 1` and `useCustomGradlePropertiesTemplate: 1` in `ProjectSettings/ProjectSettings.asset`.
- [ ] Target API Level 33 or higher. `Automatic` (highest installed) is fine; don't change it.
- [ ] `OneSignalConfig.androidlib` in `Assets/Plugins/Android` (see **OneSignal SDK Setup window steps**). Required if Minify is enabled, and the place for `google-services.xml` and icons.
- [ ] Android dependencies resolved: tell the developer to run Assets ▸ External Dependency Manager ▸ Android Resolver ▸ **Force Resolve** after opening the project. With Custom Main Gradle Template on, dependencies also resolve during a normal Unity Android build.

### Android Firebase Configuration

Follow **Android Firebase Configuration** in the shared guidelines, with these Unity differences from the official [Unity SDK setup](https://documentation.onesignal.com/docs/en/unity-sdk-setup) and [Android Firebase credentials](https://documentation.onesignal.com/docs/en/android-firebase-credentials) pages. Requires OneSignal Unity SDK 5.4.2 or later.

- [ ] Unity has **no** `com.google.gms.google-services` step. **Do not add `google-services.json` to the project.**
- [ ] Instead, ship `res/values/google-services.xml` inside an `.androidlib` under `Assets/Plugins/Android`. Detect this file instead of `google-services.json`.
- [ ] If it's missing, ask the Step 1 question, but ask the developer to keep `google-services.json` **outside `Assets/`** and tell you its path. Then either:
  * use the Firebase Unity SDK to generate `google-services.xml`, if the project already uses it, or
  * write `google-services.xml` with the four values the official guide names, from the developer's file: `google_app_id` (`client[].client_info.mobilesdk_app_id` for the matching package), `gcm_defaultSenderId` (`project_info.project_number`), `google_api_key` (`client[].api_key[0].current_key`), and `project_id` (`project_info.project_id`).
- [ ] Put it in `Assets/Plugins/Android/OneSignalConfig.androidlib/src/main/res/values/google-services.xml`. If that `.androidlib` isn't there, create it yourself as described in **OneSignal SDK Setup window steps**; don't stop to ask. Use another existing `.androidlib` only if the project already has one.
- [ ] The file format:
  ```xml
  <?xml version="1.0" encoding="utf-8"?>
  <resources>
      <string name="google_app_id" translatable="false">1:000000000000:android:0000000000000000</string>
      <string name="gcm_defaultSenderId" translatable="false">000000000000</string>
      <string name="google_api_key" translatable="false">AIza...</string>
      <string name="project_id" translatable="false">your-project-id</string>
  </resources>
  ```

### Notification Icons (Android, Recommended)

- [ ] Recommend in the summary replacing the default icons in `Assets/Plugins/Android/OneSignalConfig.androidlib/src/main/res`. Without a small icon, notifications show a default bell icon. Guide: https://documentation.onesignal.com/docs/en/notification-icons. Don't generate icons unless asked.

### iOS Build Settings

- [ ] Target minimum iOS version 15.0+ (official guide)
- [ ] **Automatically Sign** checked (Player Settings ▸ Other Settings), or manual provisioning with the App Group `group.{bundle_id}.onesignal`, Push Notifications and App Groups enabled in the Apple Developer account
- [ ] Verify the exported Xcode project has the Push Notifications and Background Modes (Remote notifications) capabilities, the App Group on BOTH targets, and the `OneSignalNotificationServiceExtension` target (all added automatically)

### Initialization

- [ ] OneSignal initialized in `Start()` of a `MonoBehaviour` early in the app's lifecycle, as in the official setup guide
- [ ] Push permission requested right after initialization with `await OneSignal.Notifications.RequestPermissionAsync(true)`, as in the official setup guide

---

## iOS Push Infrastructure

Unity exports an Xcode project for iOS, and the OneSignal Unity SDK includes an iOS build post-processor (`com.onesignal.unity.ios/Editor/BuildPostProcessor.cs`) that configures the required push infrastructure automatically on every export. Do NOT recreate it manually. The post-processor:

* Enables the Push Notifications and Background Modes (Remote notifications) capabilities on the main target
* Adds the App Group `group.{bundle_id}.onesignal` to the entitlements of BOTH the main target and the NSE
* Creates the `OneSignalNotificationServiceExtension` target with `NotificationService.swift`, `Info.plist`, and entitlements
* Appends a `target 'OneSignalNotificationServiceExtension'` block to the generated Podfile

Your job after export is to VERIFY this ran, using the "Shared iOS Push Infrastructure" section earlier in this document as the reference for what must be present (NSE target, App Group in both entitlements, Background Modes).

The Podfile block is the exception: the post-processor writes `pod 'OneSignalXCFramework/OneSignalExtension', 'X.Y.Z'`, exactly pinned to the SDK's iOS version, plus `install! 'cocoapods', :disable_input_output_paths => true`. That is expected. Don't compare it with the shared Podfile block, and don't edit it; the next export overwrites it.

Unity-specific notes:

* Open and build the exported project via **`.xcworkspace`**, not `.xcodeproj`. CocoaPods (including OneSignal) is only linked through the workspace:

```bash
cd <ExportedIosProject>
pod install   # if Pods are not already installed
xcodebuild -workspace Unity-iPhone.xcworkspace -scheme Unity-iPhone \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

* Keep normal code signing enabled — see **Code signing (do not disable)** in the Shared iOS Push Infrastructure section.
* The post-processor does NOT run on Unity Cloud Build (`UNITY_CLOUD_BUILD`) — in that case, apply the shared iOS push infrastructure setup manually to the exported project
* If a custom post-process script changes the bundle identifier, run it before OneSignal's post-processor (callback order 45) or the App Group name will be derived from the old bundle ID
* Keep the existing Unity iOS bundle identifier from Player Settings / the exported project; do not invent a new one

---

## Architecture Guidance

### Singleton Pattern (Recommended for Unity)

```
Assets/
├── Scripts/
│   ├── Managers/
│   │   └── OneSignalManager.cs     # Singleton manager, DontDestroyOnLoad
│   └── ...
└── Scenes/
    └── ...
```

### Service Locator / DI (Zenject, VContainer)

Keep the same `OneSignalManager` and bind or register it through the project's existing container. Don't introduce a container the project doesn't already use.

---

## Code Examples

### Installation (Unity Package Manager)

Follow the official guide: add the npmjs scoped registry, then install the OneSignal packages at the Current version from releases.json (Step 2). In `Packages/manifest.json`:

```json
{
  "scopedRegistries": [
    {
      "name": "npmjs",
      "url": "https://registry.npmjs.org",
      "scopes": ["com.onesignal"]
    }
  ],
  "dependencies": {
    "com.onesignal.unity.core": "X.Y.Z",
    "com.onesignal.unity.android": "X.Y.Z",
    "com.onesignal.unity.ios": "X.Y.Z"
  }
}
```

Install `com.onesignal.unity.android` and/or `com.onesignal.unity.ios` only for the platforms selected in Step 1; `core` is always required. Merge into the existing `scopedRegistries` and `dependencies` instead of replacing them.

If the project already installed OneSignal from the Asset Store or a Git URL, keep that method and update the version instead.

### OneSignal SDK Setup window steps

The official guide says to open Window ▸ OneSignal SDK Setup and complete its checklist. Its steps are file operations, so do them yourself instead of stopping to ask:

| Window step | What to do |
|-------------|------------|
| **Install EDM4U** | **Skip if any External Dependency Manager is present** (see below). The window only recognizes legacy EDM4U, so it shows this step as incomplete with Unity's EDM. Running it imports Google's archived `.unitypackage` next to Unity's EDM and duplicates the `Google.*` assemblies. Tell the developer to ignore that step. |
| **Copy Android plugin to Assets** | Copy every non-`.meta` file from `com.onesignal.unity.android`'s `Editor/OneSignalConfig.androidlib/` to `Assets/Plugins/Android/OneSignalConfig.androidlib/`. The source is in `Library/PackageCache/com.onesignal.unity.android@<version>/` once Unity has resolved packages; before that, take it from the npm tarball for the Current version (`https://registry.npmjs.org/com.onesignal.unity.android/-/com.onesignal.unity.android-X.Y.Z.tgz`). Skip if it already exists. |
| **Generate link.xml** | Copy `com.onesignal.unity.core`'s `Editor/link.xml` to `Assets/OneSignal/link.xml` (same source rules). It keeps IL2CPP stripping from removing the classes the SDK finds by reflection. |
| **Sync example code bundle** | Optional; skip. |

Re-running the window's copy step later overwrites the package files in `OneSignalConfig.androidlib` but leaves an added `google-services.xml` alone.

### Install External Dependency Manager

The OneSignal UPM packages declare their native Android/iOS libraries through an External Dependency Manager but **do not depend on one themselves**. Without it the build has **no `com.onesignal.OneSignal` native library**, and initialization fails silently at runtime with a `ClassNotFoundException`.

First detect any of these; if one is present, keep it and don't add another:
- `com.unity.external-dependency-manager` in `Packages/manifest.json` (Unity's EDM)
- `com.google.external-dependency-manager` in `Packages/manifest.json` (legacy EDM4U)
- `Assets/ExternalDependencyManager/` (legacy EDM4U imported as a `.unitypackage`)

If none is present, add Unity's EDM from the Unity registry (no scoped registry needed; requires Unity 2022.3+):

```json
{
  "dependencies": {
    "com.unity.external-dependency-manager": "2.1.1"
  }
}
```

Use the latest version: read `dist-tags.latest` from `https://packages.unity.com/com.unity.external-dependency-manager`.

Don't use Google's registry (`https://unityregistry-pa.googleapis.com`): it returns 404, and Google archived EDM4U on 2026-10-26 in favor of Unity's EDM. A manifest that references it blocks resolution of **every** package, including OneSignal's.

### Centralized Manager (OneSignalManager.cs)

Wraps every OneSignal call. Initialization only: no login, email, SMS, or tag methods (see **Scope: initialization only** in the shared guidelines). Follows the official guide: initialize in `Start()`, then request permission. Put the App ID from Step 1 in `AppId`. Add the component to a GameObject in the first scene; in a scene file, that means a new GameObject with this script attached, and the summary should name the scene.

```csharp
using UnityEngine;
using OneSignalSDK;
using OneSignalSDK.Debug.Models;

public class OneSignalManager : MonoBehaviour
{
    public static OneSignalManager Instance { get; private set; }

    // The App ID from Step 1, or the YOUR_APP_ID placeholder if it was skipped.
    // A const, not a [SerializeField]: a serialized value in the scene would override this line.
    private const string AppId = "YOUR_APP_ID";

    public bool IsInitialized { get; private set; }

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }

        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    private async void Start()
    {
        if (IsInitialized) return;

        // Enable verbose logging for debugging (remove in production)
        OneSignal.Debug.LogLevel = LogLevel.Verbose;
        OneSignal.Initialize(AppId);
        IsInitialized = true;

        // As in the official guide. In production, consider an in-app message instead for better opt-in rates.
        await OneSignal.Notifications.RequestPermissionAsync(true);
    }

    public void SetLogLevel(LogLevel level)
    {
        OneSignal.Debug.LogLevel = level;
    }
}
```

> **Notes:**
> - `LogLevel` is in `OneSignalSDK.Debug.Models`; the official snippet omits that `using`, but it's required.
> - Use `UnityEngine.Debug.Log()` instead of `Debug.Log()` to avoid conflicts with `OneSignal.Debug`.
> - The OneSignal **App ID is a public identifier, not a secret**; it's safe to commit. Never embed REST API keys in the app.

---

## Verification

Give the developer these steps in the Changes Summary, following the official guide:

1. Build and run on a device or emulator. **Not the Editor:** in Play mode the OneSignal native layer is a no-op, so nothing registers and no prompt appears. If you test on an Android emulator, cold-boot it first. The permission prompt appears at launch.
2. Before accepting, open **Audience → Users & subscriptions → Subscriptions** in the OneSignal dashboard. The new Subscription shows **Never Subscribed**.
3. Tap **Allow** on the prompt.
4. Refresh the dashboard. The status changes to **Subscribed**.
5. Send a test push. This needs FCM credentials (Android) and APNs credentials (iOS) in the OneSignal dashboard.

On Android, OneSignal's logs go to `adb logcat -s OneSignal:V`, not the Unity Console.

Do **not** reinstall or wipe the app just to re-check; that creates a second OneSignal subscription.

---

## After Setup: Push Credentials in OneSignal

In the Changes Summary, for each platform selected in Step 1:

- **Android:** use the shared **After setup: FCM credentials in OneSignal** note.
- **iOS:** > **Push won't reach iOS devices until your OneSignal app has APNs credentials.** In OneSignal, go to **Settings → Push & In-App → Apple iOS (APNs)** and add your p8 Auth Key (recommended) or p12 Certificate.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| iOS build fails | Run EDM4U iOS Resolver, check Xcode capabilities |
| iOS push received but no image | Verify the OneSignal build post-processor ran on export — the NSE target and App Group must be present |
| No Confirmed Delivery stat | Verify NSE + App Group setup in the exported Xcode project; dashboard display requires a paid OneSignal plan |
| Xcode provisioning errors mentioning the App Group | Select a valid Team with Automatically Sign, refresh App Groups in Signing & Capabilities for BOTH targets, or pre-register the App Group in the Apple Developer portal |
| `ClassNotFoundException` / no `com.onesignal.OneSignal` at runtime (silent init failure) | No External Dependency Manager, or Android deps never resolved — add `com.unity.external-dependency-manager`, enable Custom Main Gradle Template, then Force Resolve |
| Package Manager fails to resolve; `OneSignalSDK` namespace missing | Check `Packages/manifest.json` for a scoped registry at `unityregistry-pa.googleapis.com`. It returns 404 and blocks every package; remove it and use `com.unity.external-dependency-manager` |
| Duplicate `Google.*` assembly errors | Both Unity's EDM and legacy EDM4U (`Assets/ExternalDependencyManager`) are installed, often from the setup window's **Install EDM4U** step. Keep one |
| "Could not find an implementation of OneSignal SDK" | IL2CPP stripped the platform classes; add `Assets/OneSignal/link.xml` (see **OneSignal SDK Setup window steps**) |
| "Force Resolve" fails with `GroovyBugError` / `ReflectionCache` | The legacy standalone resolver can crash on JDK 17. With Custom Main Gradle Template enabled, the dependencies still resolve during the normal Unity Android build |
| Permission prompt never appears | Expected in the Editor (native layer is a no-op). On a device, confirm `OneSignalManager` is in the first scene; check `adb logcat -s OneSignal:V` |
| Multiple instances | Ensure only one GameObject with `OneSignalManager` |
| `OneSignalSDK` namespace not found | Confirm the packages installed from the npmjs scoped registry and `com.onesignal.unity.core` is present |
| `LogLevel` not found | Add `using OneSignalSDK.Debug.Models;` |
| Android subscription status -32 or -33 | `google-services.xml` missing, or from a different Firebase project than the FCM Service Account in OneSignal |
