# Unity Platform Integration

## Official Documentation

* [OneSignal Unity SDK Setup](https://documentation.onesignal.com/docs/unity-sdk-setup)
* [Unity SDK API Reference](https://documentation.onesignal.com/docs/unity-sdk-api-reference)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-Unity-SDK)

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Unity Configuration

- [ ] Unity version 2021.3 LTS or newer (recommended)
- [ ] Unity version 2018.4+ minimum supported

### Package Installation

- [ ] OneSignal Unity SDK installed via Unity Package Manager or `.unitypackage`
- [ ] External Dependency Manager (EDM4U) installed **explicitly** — it is NOT bundled with or pulled in by the OneSignal packages (see "Install External Dependency Manager (EDM4U)" below)

### Android Build Settings

- [ ] Minimum API Level 21 (Android 5.0) or higher
- [ ] Target API Level 33+ recommended
- [ ] Custom Main Manifest enabled if modifying AndroidManifest.xml
- [ ] Custom Main Gradle Template enabled (Player Settings ▸ Publishing Settings) so EDM4U can resolve Android dependencies on JDK 17
- [ ] Internet permission granted (automatic with OneSignal)

Note: The OneSignal SDK handles FCM registration itself. Do NOT add the Google Services Gradle plugin or a `google-services.json` file — they are not required. Push credentials (the Firebase Service Account JSON) are configured in the OneSignal dashboard, not in the app.

### iOS Build Settings

- [ ] Target minimum iOS version 11.0+
- [ ] Enable Push Notifications capability in Xcode after build
- [ ] Enable Background Modes > Remote notifications in Xcode
- [ ] APNs key/certificate uploaded to OneSignal dashboard

### Initialization

- [ ] OneSignal initialized in a startup script or first scene
- [ ] `RuntimeInitializeOnLoadMethod` or `Awake()` used for early initialization

---

## Architecture Guidance

### Singleton Pattern (Recommended for Unity)

```
Assets/
├── Scripts/
│   ├── Managers/
│   │   └── OneSignalManager.cs     # Singleton manager
│   └── ...
├── Prefabs/
│   └── Managers/
│       └── OneSignalManager.prefab # DontDestroyOnLoad
└── Scenes/
    └── ...
```

### Service Locator Pattern

```
Assets/
├── Scripts/
│   ├── Services/
│   │   ├── INotificationService.cs
│   │   └── OneSignalNotificationService.cs
│   ├── Core/
│   │   └── ServiceLocator.cs
│   └── ...
```

### Zenject/VContainer (DI Framework)

```
Assets/
├── Scripts/
│   ├── Installers/
│   │   └── ProjectInstaller.cs     # Bind OneSignal service
│   ├── Services/
│   │   └── OneSignalService.cs
│   └── ...
```

---

## Threading Model

Unity is single-threaded for most operations. OneSignal SDK handles its own threading internally.

### Main Thread Callbacks

```csharp
using OneSignalSDK;
using OneSignalSDK.Notifications;

// OneSignal callbacks are already on the main thread
// Events use standard EventHandler<T> pattern with (object sender, EventArgs e) signature
OneSignal.Notifications.Clicked += (sender, e) =>
{
    // Safe to access Unity objects here
    // Use UnityEngine.Debug to avoid conflict with OneSignal.Debug
    UnityEngine.Debug.Log($"Notification clicked: {e.Notification.Title}");
};

OneSignal.Notifications.ForegroundWillDisplay += (sender, e) =>
{
    UnityEngine.Debug.Log($"Notification received: {e.Notification.Title}");
    // Call e.PreventDefault() to suppress the notification display
};

OneSignal.Notifications.PermissionChanged += (sender, e) =>
{
    UnityEngine.Debug.Log($"Permission changed: {e.Permission}");
};
```

### Background Operations (if needed)

```csharp
using System.Threading.Tasks;

public class OneSignalManager : MonoBehaviour
{
    public async Task<bool> InitializeAsync(string appId)
    {
        return await Task.Run(() =>
        {
            OneSignal.Initialize(appId);
            return true;
        });
    }
}
```

### UniTask (Recommended for Unity async)

```csharp
using Cysharp.Threading.Tasks;

public class OneSignalManager : MonoBehaviour
{
    public async UniTaskVoid InitializeAsync(string appId)
    {
        await UniTask.SwitchToThreadPool();
        OneSignal.Initialize(appId);
        await UniTask.SwitchToMainThread();
        Debug.Log("OneSignal initialized");
    }
}
```

---

## Code Examples

### Installation (Unity Package Manager)

Add to `Packages/manifest.json`:
```json
{
  "dependencies": {
    "com.onesignal.unity.core": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=com.onesignal.unity.core#5.1.15",
    "com.onesignal.unity.android": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=com.onesignal.unity.android#5.1.15",
    "com.onesignal.unity.ios": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=com.onesignal.unity.ios#5.1.15"
  }
}
```

> **Important:** Always include a version tag (e.g., `#5.1.15`) to ensure reproducible builds. `5.1.15` is shown only as an example — confirm the current **Stable** version from the releases page (see Step 2) before using it; do not copy this number blindly. The `core` package must be listed first as it is a dependency of the platform packages. Do not include a leading `/` in the path parameter.

Or use the Unity Asset Store / .unitypackage from GitHub releases.

### Install External Dependency Manager (EDM4U) — Required

The three OneSignal UPM packages above declare their native Android/iOS libraries through EDM4U (via a `Dependencies.xml` manifest) but **do NOT depend on EDM4U themselves**. If you only add those packages, the resulting build contains **no `com.onesignal.OneSignal` native library** — initialization fails silently at runtime with a `ClassNotFoundException`. You must install EDM4U explicitly:

**Option A — scoped registry (recommended).** Add Google's registry to `Packages/manifest.json`, then install the package:

```json
{
  "scopedRegistries": [
    {
      "name": "Google",
      "url": "https://unityregistry-pa.googleapis.com",
      "scopes": ["com.google"]
    }
  ],
  "dependencies": {
    "com.google.external-dependency-manager": "1.2.186"
  }
}
```

> Pin `com.google.external-dependency-manager` to the current version published in that registry (the value above is an example — verify the latest). You can also add it via **Window ▸ Package Manager ▸ Google ▸ External Dependency Manager for Unity ▸ Install**, which selects the version for you.

**Option B — `.unitypackage`.** Import the latest `external-dependency-manager-*.unitypackage` from [googlesamples/unity-jar-resolver](https://github.com/googlesamples/unity-jar-resolver).

### Enable the Custom Main Gradle Template — Required for Android

On modern Unity, let EDM4U resolve Android dependencies **through Unity's build Gradle**, not its standalone resolver:

1. Open **Player Settings ▸ Publishing Settings** and enable **Custom Main Gradle Template**. This generates `Assets/Plugins/Android/mainTemplate.gradle`, which EDM4U patches with the OneSignal Android dependencies as part of the normal build.
2. Do **NOT** rely on EDM4U's **"Force Resolve"** alone. Its standalone resolver runs Gradle 5.1.1, which crashes on JDK 17 (`GroovyBugError` / `ReflectionCache`) — and you cannot downgrade the JDK because Unity 6 + Android Gradle Plugin 8 require JDK 17.

With the Custom Main Gradle Template enabled, the OneSignal native libraries resolve during the standard Unity Android build.

### Initialization Script

```csharp
using UnityEngine;
using OneSignalSDK;
using OneSignalSDK.Debug.Models;

public class OneSignalInitializer : MonoBehaviour
{
    [SerializeField] private string appId = "YOUR_ONESIGNAL_APP_ID";

    private void Awake()
    {
        // Initialize OneSignal
        OneSignal.Initialize(appId);

        // Set log level for debugging (use PascalCase for enum values)
        OneSignal.Debug.LogLevel = LogLevel.Verbose;
        OneSignal.Debug.AlertLevel = LogLevel.None;

        // Do NOT request push permission here — the verification dialog
        // (see "Push Subscription Verification Dialog") requests it on tap.

        // Keep this object alive across scenes
        DontDestroyOnLoad(gameObject);
    }
}
```

> **Note:** The `LogLevel` enum is in the `OneSignalSDK.Debug.Models` namespace and uses PascalCase values: `None`, `Fatal`, `Error`, `Warn`, `Info`, `Debug`, `Verbose`.

> **Note:** The OneSignal **App ID is a public identifier, not a secret** — it ships inside the app binary and is safe to commit and hardcode. The "do not commit secrets" rule applies only to **REST API keys**, which must never be embedded in the app.

### Using RuntimeInitializeOnLoadMethod

```csharp
using UnityEngine;
using OneSignalSDK;
using OneSignalSDK.Debug.Models;

public static class OneSignalBootstrap
{
    private const string APP_ID = "YOUR_ONESIGNAL_APP_ID";

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void Initialize()
    {
        OneSignal.Initialize(APP_ID);
        OneSignal.Debug.LogLevel = LogLevel.Verbose;
    }
}
```

### Centralized Manager

```csharp
using UnityEngine;
using OneSignalSDK;
using OneSignalSDK.Notifications;
using OneSignalSDK.Notifications.Models;
using OneSignalSDK.Debug.Models;
using System;

public class OneSignalManager : MonoBehaviour
{
    public static OneSignalManager Instance { get; private set; }

    [SerializeField] private string appId;

    // Use correct interface types from OneSignalSDK.Notifications.Models
    public event Action<IDisplayableNotification> OnNotificationReceived;
    public event Action<INotificationClickResult> OnNotificationClicked;

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

        Initialize();
    }

    private void Initialize()
    {
        if (IsInitialized) return;

        if (string.IsNullOrEmpty(appId))
        {
            UnityEngine.Debug.LogError("OneSignal App ID is not set!");
            return;
        }

        OneSignal.Initialize(appId);
        SetupListeners();
        IsInitialized = true;
    }

    private void SetupListeners()
    {
        // Events use EventHandler<T> pattern: (object sender, TEventArgs e)
        OneSignal.Notifications.ForegroundWillDisplay += (sender, e) =>
        {
            OnNotificationReceived?.Invoke(e.Notification);
            // Call e.PreventDefault() to suppress the notification display
        };

        OneSignal.Notifications.Clicked += (sender, e) =>
        {
            OnNotificationClicked?.Invoke(e.Result);
        };
    }

    public void Login(string externalId)
    {
        OneSignal.Login(externalId);
    }

    public void Logout()
    {
        OneSignal.Logout();
    }

    public void SetEmail(string email)
    {
        OneSignal.User.AddEmail(email);
    }

    public void SetSmsNumber(string number)
    {
        OneSignal.User.AddSms(number);
    }

    public void SetTag(string key, string value)
    {
        OneSignal.User.AddTag(key, value);
    }

    public async void RequestPermission(Action<bool> callback = null)
    {
        bool accepted = await OneSignal.Notifications.RequestPermissionAsync(true);
        callback?.Invoke(accepted);
    }

    public void SetLogLevel(LogLevel level)
    {
        OneSignal.Debug.LogLevel = level;
    }
}
```

> **Important Notes:**
> - Use `UnityEngine.Debug.Log()` instead of `Debug.Log()` to avoid conflicts with `OneSignal.Debug`
> - Event handlers use the standard `EventHandler<T>` signature: `(object sender, TEventArgs e)`
> - The correct type is `INotificationClickResult` (not `INotificationClickedResult`)
> - `IDisplayableNotification` is used for foreground notifications, `INotification` for clicked notifications

---

## Push Subscription Verification Dialog

After completing SDK initialization, add a push subscription observer so the app can confirm that the device registered successfully. When the subscription ID is received, show a dialog and request push permission on tap.

Unity has no native alert dialog, so this uses a lightweight IMGUI overlay. Attach this component to a GameObject in your first scene (or create it from `OneSignalManager`) after OneSignal is initialized.

> **Wrapper-rule exception:** Step 4 requires routing OneSignal calls through your centralized wrapper. The verification dialog is a **sanctioned exception** — it may call `OneSignal.User.PushSubscription` and `OneSignal.Notifications.RequestPermissionAsync` directly. If you prefer to keep the rule strict, expose these through `OneSignalManager` (e.g. its `RequestPermission` method) and call that instead.

### IntegrationCompleteDialog.cs

```csharp
using UnityEngine;
using OneSignalSDK;

public class IntegrationCompleteDialog : MonoBehaviour
{
    private bool showDialog = false;
    private bool dialogShown = false;

    private void Start()
    {
        // Register the push subscription observer after OneSignal is initialized.
        // Event handlers use the standard (object sender, TEventArgs e) signature.
        OneSignal.User.PushSubscription.Changed += (sender, e) =>
        {
            MaybeShowDialog(e.State.Current.Id);
        };

        // The ID may already be assigned before the observer attaches,
        // so evaluate the current value immediately as well.
        MaybeShowDialog(OneSignal.User.PushSubscription.Id);
    }

    // A real, server-assigned subscription ID is non-empty and not the local- placeholder
    private static bool IsRegistered(string subscriptionId) =>
        !string.IsNullOrEmpty(subscriptionId) && !subscriptionId.StartsWith("local-");

    private void MaybeShowDialog(string subscriptionId)
    {
        if (IsRegistered(subscriptionId) && !dialogShown)
        {
            dialogShown = true;
            showDialog = true;
        }
    }

    private void OnGUI()
    {
        if (!showDialog) return;

        GUILayout.BeginArea(new Rect(Screen.width / 2 - 200, Screen.height / 2 - 100, 400, 200), GUI.skin.box);

        GUILayout.Label("Your OneSignal SDK integration is complete!",
            new GUIStyle(GUI.skin.label) { fontSize = 18, alignment = TextAnchor.MiddleCenter });
        GUILayout.Space(10);
        GUILayout.Label("You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.",
            new GUIStyle(GUI.skin.label) { wordWrap = true, alignment = TextAnchor.MiddleCenter });
        GUILayout.Space(20);

        if (GUILayout.Button("Got it", GUILayout.Height(40)))
        {
            showDialog = false;
            RequestPushPermission();
        }

        GUILayout.EndArea();
    }

    private async void RequestPushPermission()
    {
        await OneSignal.Notifications.RequestPermissionAsync(true);
    }
}
```

> **Verifying requires a real device or emulator build — it will NOT work in the Editor.**
>
> - In **Editor Play mode the OneSignal native layer is a no-op**: the device never registers, no server-assigned subscription ID is issued, and the verification dialog will **never** appear. Build and run on a physical device or an Android emulator to see it. An empty Unity Console in the Editor does **not** mean the integration failed.
> - On Android, OneSignal's logs go to **`adb logcat`**, not the Unity Console. Filter them with:
>
> ```bash
> adb logcat -s OneSignal:V
> ```

---

## Testing

> **Note:** Play Mode tests run in the Editor, where the OneSignal native layer is a no-op. They can verify your C#/MonoBehaviour wiring (manager creation, listener setup) but **cannot** verify push registration, subscription IDs, or the verification dialog — those require a device/emulator build (see the verification note above).

### Play Mode Tests

```csharp
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using System.Collections;

public class OneSignalManagerTests
{
    [UnityTest]
    public IEnumerator OneSignalManager_Initializes_Successfully()
    {
        // Arrange
        var go = new GameObject("TestManager");
        var manager = go.AddComponent<OneSignalManager>();
        
        yield return null;
        
        // Assert
        Assert.IsNotNull(OneSignalManager.Instance);
        
        // Cleanup
        Object.Destroy(go);
    }
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| iOS build fails | Run EDM4U iOS Resolver, check Xcode capabilities |
| Android build fails | Enable Custom Main Gradle Template (Player Settings ▸ Publishing Settings) so EDM4U patches `mainTemplate.gradle` |
| `ClassNotFoundException` / no `com.onesignal.OneSignal` at runtime (silent init failure) | EDM4U is missing or Android deps never resolved — install EDM4U explicitly and enable Custom Main Gradle Template (see "Install External Dependency Manager") |
| EDM4U "Force Resolve" fails with `GroovyBugError` / `ReflectionCache` | Its standalone resolver runs Gradle 5.1.1, which crashes on JDK 17 — resolve via Custom Main Gradle Template instead of Force Resolve |
| Verification dialog never appears | Expected in the Editor (native layer is a no-op) — build to a device/emulator; check `adb logcat -s OneSignal:V` |
| Notifications not received | Verify platform configuration in OneSignal dashboard |
| Permission not requested | Permission is requested when the user taps "Got it" on the verification dialog |
| SDK not initializing | Check App ID is correct, verify internet connectivity |
| Multiple instances | Ensure only one GameObject with OneSignal initialization |
| `OneSignalSDK` namespace not found | Ensure packages have version tags in manifest.json (e.g., `#5.1.15`), remove leading `/` from paths |
| `LogLevel` not found | Add `using OneSignalSDK.Debug.Models;` |
| `INotification` not found | Add `using OneSignalSDK.Notifications.Models;` |
| Event handler signature error | Use `(object sender, TEventArgs e)` pattern, not just `(e)` |
| `Debug.Log` conflicts with `OneSignal.Debug` | Use `UnityEngine.Debug.Log()` explicitly |
| "OneSignal not initialized" error | Ensure `OneSignal.Initialize()` is called before using other SDK methods |
| Package resolution fails | Check version tag exists (use `5.1.15` not `5.2.8`), verify `core` package is listed first |
