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
- [ ] External Dependency Manager (EDM4U) installed for Android/iOS dependencies

### Android Build Settings

- [ ] Minimum API Level 21 (Android 5.0) or higher
- [ ] Target API Level 33+ recommended
- [ ] Custom Main Manifest enabled if modifying AndroidManifest.xml
- [ ] Internet permission granted (automatic with OneSignal)
- [ ] `google-services.json` in `Assets/Plugins/Android/` (if using FCM)

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
// OneSignal callbacks are already on the main thread
OneSignal.Notifications.Clicked += (notification) =>
{
    // Safe to access Unity objects here
    Debug.Log($"Notification clicked: {notification.title}");
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
    "com.onesignal.unity.android": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=/com.onesignal.unity.android",
    "com.onesignal.unity.ios": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=/com.onesignal.unity.ios",
    "com.onesignal.unity.core": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=/com.onesignal.unity.core"
  }
}
```

Or use the Unity Asset Store / .unitypackage from GitHub releases.

### Initialization Script

```csharp
using UnityEngine;
using OneSignalSDK;

public class OneSignalInitializer : MonoBehaviour
{
    [SerializeField] private string appId = "YOUR_ONESIGNAL_APP_ID";
    
    private void Awake()
    {
        // Initialize OneSignal
        OneSignal.Initialize(appId);
        
        // Set log level for debugging
        OneSignal.Debug.LogLevel = LogLevel.VERBOSE;
        OneSignal.Debug.AlertLevel = LogLevel.NONE;
        
        // Request notification permission
        OneSignal.Notifications.RequestPermissionAsync(true);
        
        // Keep this object alive across scenes
        DontDestroyOnLoad(gameObject);
    }
}
```

### Using RuntimeInitializeOnLoadMethod

```csharp
using UnityEngine;
using OneSignalSDK;

public static class OneSignalBootstrap
{
    private const string APP_ID = "YOUR_ONESIGNAL_APP_ID";
    
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void Initialize()
    {
        // Set log level for debugging (remove in production)
        OneSignal.Debug.LogLevel = LogLevel.Verbose;
        // Initialize OneSignal
        OneSignal.Initialize(APP_ID);
    }
}
```

### Centralized Manager

```csharp
using UnityEngine;
using OneSignalSDK;
using System;

public class OneSignalManager : MonoBehaviour
{
    public static OneSignalManager Instance { get; private set; }
    
    [SerializeField] private string appId;
    
    public event Action<INotification> OnNotificationReceived;
    public event Action<INotificationClickedResult> OnNotificationClicked;
    
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
        if (string.IsNullOrEmpty(appId))
        {
            Debug.LogError("OneSignal App ID is not set!");
            return;
        }
        
        // Set log level for debugging (remove in production)
        OneSignal.Debug.LogLevel = LogLevel.Verbose;
        // Initialize OneSignal
        OneSignal.Initialize(appId);
        SetupListeners();
    }
    
    private void SetupListeners()
    {
        OneSignal.Notifications.ForegroundWillDisplay += (notification) =>
        {
            OnNotificationReceived?.Invoke(notification.Notification);
            notification.PreventDefault(); // Show notification in foreground
        };
        
        OneSignal.Notifications.Clicked += (result) =>
        {
            OnNotificationClicked?.Invoke(result);
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

---

## Push Subscription Observer + Welcome Dialog (Unity IMGUI)

After completing the integration, add a push subscription observer that shows a dialog when the device receives a push subscription ID. Since Unity does not have a built-in native dialog API at runtime, use an IMGUI overlay as a lightweight popup.

```csharp
using UnityEngine;
using System.Collections;
using OneSignalSDK;

public class WelcomeDialog : MonoBehaviour
{
    private bool showDialog = false;

    private void Start()
    {
        OneSignal.User.PushSubscription.Changed += OnPushSubscriptionChanged;
    }

    private void OnPushSubscriptionChanged(object sender, PushSubscriptionChangedEventArgs e)
    {
        var previousId = e.State.Previous.Id;
        var currentId = e.State.Current.Id;

        if (string.IsNullOrEmpty(previousId) && !string.IsNullOrEmpty(currentId))
        {
            StartCoroutine(ShowDialogAfterDelay(1.0f));
        }
    }

    private IEnumerator ShowDialogAfterDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        showDialog = true;
    }

    private void OnGUI()
    {
        if (!showDialog) return;

        // Center a dialog box on screen
        float width = 400;
        float height = 150;
        Rect dialogRect = new Rect(
            (Screen.width - width) / 2,
            (Screen.height - height) / 2,
            width,
            height
        );

        GUI.Window(0, dialogRect, _ =>
        {
            GUILayout.Space(10);
            GUILayout.Label("Click the button below to trigger your first journey via an in-app message.",
                new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter, wordWrap = true });
            GUILayout.Space(10);
            if (GUILayout.Button("Trigger your first journey"))
            {
                OneSignal.InAppMessages.SetTrigger("ai_implementation_campaign_email_journey", "true");
                showDialog = false;
            }
        }, "Your OneSignal integration is complete!");
    }

    private void OnDestroy()
    {
        OneSignal.User.PushSubscription.Changed -= OnPushSubscriptionChanged;
    }
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| iOS build fails | Run EDM4U iOS Resolver, check Xcode capabilities |
| Android build fails | Run EDM4U Android Resolver, check `google-services.json` |
| Notifications not received | Verify platform configuration in OneSignal dashboard |
| Permission not requested | Call `RequestPermissionAsync` after initialization |
| SDK not initializing | Check App ID is correct, verify internet connectivity |
| Multiple instances | Ensure only one GameObject with OneSignal initialization |
