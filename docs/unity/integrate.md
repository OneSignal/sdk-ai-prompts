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
    "com.onesignal.unity.core": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=com.onesignal.unity.core#5.1.16",
    "com.onesignal.unity.android": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=com.onesignal.unity.android#5.1.16",
    "com.onesignal.unity.ios": "https://github.com/OneSignal/OneSignal-Unity-SDK.git?path=com.onesignal.unity.ios#5.1.16"
  }
}
```

> **Important:** Always include a version tag (e.g., `#5.1.16`) to ensure reproducible builds. The `core` package must be listed first as it is a dependency of the platform packages. Do not include a leading `/` in the path parameter.

Or use the Unity Asset Store / .unitypackage from GitHub releases.

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

        // Request notification permission
        OneSignal.Notifications.RequestPermissionAsync(true);

        // Keep this object alive across scenes
        DontDestroyOnLoad(gameObject);
    }
}
```

> **Note:** The `LogLevel` enum is in the `OneSignalSDK.Debug.Models` namespace and uses PascalCase values: `None`, `Fatal`, `Error`, `Warn`, `Info`, `Debug`, `Verbose`.

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

## Demo Welcome View (Unity UI)

When using the demo App ID, create this view:

### WelcomeUI.cs

```csharp
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using OneSignalSDK;
using System.Text.RegularExpressions;

public class WelcomeUI : MonoBehaviour
{
    [Header("Form Elements")]
    [SerializeField] private TMP_InputField emailInput;
    [SerializeField] private TMP_InputField phoneInput;
    [SerializeField] private Button submitButton;
    [SerializeField] private TMP_Text emailErrorText;
    [SerializeField] private TMP_Text phoneErrorText;

    [Header("Loading")]
    [SerializeField] private GameObject loadingIndicator;

    [Header("Views")]
    [SerializeField] private GameObject formView;
    [SerializeField] private GameObject successView;

    private readonly Regex emailRegex = new Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    private readonly Regex phoneRegex = new Regex(@"^\+[1-9]\d{9,14}$");

    private void Start()
    {
        // Ensure OneSignal is initialized before UI interactions
        EnsureOneSignalInitialized();

        emailInput.onValueChanged.AddListener(_ => ValidateForm());
        phoneInput.onValueChanged.AddListener(_ => ValidateForm());
        submitButton.onClick.AddListener(OnSubmitClicked);

        ValidateForm();
    }

    private void EnsureOneSignalInitialized()
    {
        // Initialize OneSignal if not already done
        // This ensures the SDK is ready when the user submits the form
        if (OneSignalManager.Instance == null)
        {
            var managerObj = new GameObject("OneSignalManager");
            managerObj.AddComponent<OneSignalManager>();
        }
    }

    private void ValidateForm()
    {
        string email = emailInput.text;
        string phone = phoneInput.text;

        bool emailValid = string.IsNullOrEmpty(email) || emailRegex.IsMatch(email);
        bool phoneValid = string.IsNullOrEmpty(phone) || phoneRegex.IsMatch(phone);

        emailErrorText.gameObject.SetActive(!emailValid);
        phoneErrorText.gameObject.SetActive(!phoneValid);

        bool formComplete = !string.IsNullOrEmpty(email) && !string.IsNullOrEmpty(phone);
        bool formValid = emailRegex.IsMatch(email) && phoneRegex.IsMatch(phone);

        submitButton.interactable = formComplete && formValid;
    }

    private async void OnSubmitClicked()
    {
        submitButton.interactable = false;
        loadingIndicator.SetActive(true);

        string email = emailInput.text;
        string phone = phoneInput.text;

        try
        {
            // Set user data
            OneSignal.User.AddEmail(email);
            OneSignal.User.AddSms(phone);
            OneSignal.User.AddTag("demo_user", "true");
            OneSignal.User.AddTag("welcome_sent", System.DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString());

            // Small delay to ensure data is sent
            await System.Threading.Tasks.Task.Delay(500);

            ShowSuccess();
        }
        catch (System.Exception e)
        {
            // Use UnityEngine.Debug to avoid conflict with OneSignal.Debug
            UnityEngine.Debug.LogError($"Error submitting: {e.Message}");
            submitButton.interactable = true;
            loadingIndicator.SetActive(false);
        }
    }

    private void ShowSuccess()
    {
        formView.SetActive(false);
        successView.SetActive(true);
    }
}
```

### UI Setup Instructions

Create a Canvas with the following hierarchy:

```
Canvas
├── FormView
│   ├── TitleText ("OneSignal Integration Complete!")
│   ├── SubtitleText ("Enter your details...")
│   ├── EmailInputField
│   │   └── EmailErrorText ("Invalid email address")
│   ├── PhoneInputField
│   │   └── PhoneErrorText ("Use format: +1234567890")
│   ├── LoadingIndicator (Image with rotation animation)
│   └── SubmitButton ("Send Welcome Message")
└── SuccessView (initially disabled)
    ├── CheckmarkImage
    ├── SuccessTitleText ("Success!")
    └── SuccessMessageText ("Check your email and phone...")
```

### Alternative: IMGUI Version (Quick Testing)

```csharp
using UnityEngine;
using OneSignalSDK;
using System.Text.RegularExpressions;

public class WelcomeIMGUI : MonoBehaviour
{
    private string email = "";
    private string phone = "";
    private bool showSuccess = false;
    private bool isLoading = false;

    private readonly Regex emailRegex = new Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    private readonly Regex phoneRegex = new Regex(@"^\+[1-9]\d{9,14}$");

    private void Start()
    {
        // Ensure OneSignal is initialized
        EnsureOneSignalInitialized();
    }

    private void EnsureOneSignalInitialized()
    {
        if (OneSignalManager.Instance == null)
        {
            var managerObj = new GameObject("OneSignalManager");
            managerObj.AddComponent<OneSignalManager>();
        }
    }

    private void OnGUI()
    {
        GUILayout.BeginArea(new Rect(Screen.width / 2 - 200, Screen.height / 2 - 150, 400, 300));

        if (showSuccess)
        {
            DrawSuccess();
        }
        else
        {
            DrawForm();
        }

        GUILayout.EndArea();
    }

    private void DrawForm()
    {
        GUILayout.Label("OneSignal Integration Complete!",
            new GUIStyle(GUI.skin.label) { fontSize = 24, alignment = TextAnchor.MiddleCenter });
        GUILayout.Space(10);
        GUILayout.Label("Enter your details to receive a welcome message",
            new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter });
        GUILayout.Space(20);

        GUILayout.Label("Email Address:");
        email = GUILayout.TextField(email, GUILayout.Height(30));

        bool emailValid = string.IsNullOrEmpty(email) || emailRegex.IsMatch(email);
        if (!emailValid)
            GUILayout.Label("Invalid email address", new GUIStyle(GUI.skin.label) { normal = { textColor = Color.red } });

        GUILayout.Space(10);

        GUILayout.Label("Phone Number:");
        phone = GUILayout.TextField(phone, GUILayout.Height(30));

        bool phoneValid = string.IsNullOrEmpty(phone) || phoneRegex.IsMatch(phone);
        if (!phoneValid)
            GUILayout.Label("Use format: +1234567890", new GUIStyle(GUI.skin.label) { normal = { textColor = Color.red } });

        GUILayout.Space(20);

        bool canSubmit = emailRegex.IsMatch(email) && phoneRegex.IsMatch(phone) && !isLoading;

        GUI.enabled = canSubmit;
        if (GUILayout.Button(isLoading ? "Sending..." : "Send Welcome Message", GUILayout.Height(40)))
        {
            Submit();
        }
        GUI.enabled = true;
    }

    private void DrawSuccess()
    {
        GUILayout.FlexibleSpace();
        GUILayout.Label("Success!", new GUIStyle(GUI.skin.label) { fontSize = 28, alignment = TextAnchor.MiddleCenter });
        GUILayout.Label("Check your email and phone for a welcome message!",
            new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter });
        GUILayout.FlexibleSpace();
    }

    private async void Submit()
    {
        isLoading = true;

        OneSignal.User.AddEmail(email);
        OneSignal.User.AddSms(phone);
        OneSignal.User.AddTag("demo_user", "true");
        OneSignal.User.AddTag("welcome_sent", System.DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString());

        await System.Threading.Tasks.Task.Delay(500);

        isLoading = false;
        showSuccess = true;
    }
}
```

---

## Testing

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

### Edit Mode Tests

```csharp
using NUnit.Framework;

public class WelcomeUIValidationTests
{
    [Test]
    public void EmailValidation_ValidEmail_ReturnsTrue()
    {
        var regex = new System.Text.RegularExpressions.Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
        Assert.IsTrue(regex.IsMatch("test@example.com"));
    }
    
    [Test]
    public void EmailValidation_InvalidEmail_ReturnsFalse()
    {
        var regex = new System.Text.RegularExpressions.Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
        Assert.IsFalse(regex.IsMatch("invalid-email"));
    }
    
    [Test]
    public void PhoneValidation_ValidE164_ReturnsTrue()
    {
        var regex = new System.Text.RegularExpressions.Regex(@"^\+[1-9]\d{9,14}$");
        Assert.IsTrue(regex.IsMatch("+14155551234"));
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
| `OneSignalSDK` namespace not found | Ensure packages have version tags in manifest.json (e.g., `#5.1.16`), remove leading `/` from paths |
| `LogLevel` not found | Add `using OneSignalSDK.Debug.Models;` |
| `INotification` not found | Add `using OneSignalSDK.Notifications.Models;` |
| Event handler signature error | Use `(object sender, TEventArgs e)` pattern, not just `(e)` |
| `Debug.Log` conflicts with `OneSignal.Debug` | Use `UnityEngine.Debug.Log()` explicitly |
| "OneSignal not initialized" error | Ensure `OneSignal.Initialize()` is called before using other SDK methods |
| Package resolution fails | Check version tag exists (use `5.1.16` not `5.2.8`), verify `core` package is listed first |
