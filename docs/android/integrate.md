# Android Platform Integration

## Official Documentation

* [OneSignal Android SDK Setup](https://documentation.onesignal.com/docs/android-sdk-setup)
* [Android SDK API Reference](https://documentation.onesignal.com/docs/android-sdk-api-reference)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-Android-SDK)

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Permissions

- [ ] `INTERNET` permission in `AndroidManifest.xml`
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```
- [ ] `POST_NOTIFICATIONS` permission for Android 13+ (SDK handles this, but verify it's not blocked)

### Build Configuration

- [ ] `minSdkVersion` is 21 or higher
- [ ] `compileSdkVersion` is 33 or higher (recommended)

Note: Do NOT add the Google Services Gradle plugin or a `google-services.json` file for OneSignal — the SDK registers for FCM itself and these files are not required.

### ProGuard/R8 (if minification is enabled)

- [ ] OneSignal ProGuard rules are included (SDK usually handles this automatically)
- [ ] Test release builds to ensure nothing is stripped incorrectly

### Initialization

- [ ] OneSignal is initialized in `Application.onCreate()` or via AndroidX Startup
- [ ] Initialization happens BEFORE any other OneSignal calls

---

## Architecture Guidance

### MVVM (Recommended)

If the project uses MVVM architecture, place OneSignal logic in:

```
app/
├── src/main/java/com/example/
│   ├── data/
│   │   └── repository/
│   │       └── NotificationRepository.kt  # OneSignal wrapper
│   ├── di/
│   │   └── AppModule.kt                    # Provide as singleton
│   └── MyApplication.kt                    # Initialize here
```

### Clean Architecture

```
app/
├── data/
│   └── notification/
│       └── OneSignalNotificationService.kt
├── domain/
│   └── notification/
│       └── NotificationService.kt          # Interface
└── di/
    └── NotificationModule.kt
```

### Simple/No Architecture

```
app/
├── src/main/java/com/example/
│   ├── OneSignalManager.kt                 # Singleton wrapper
│   └── MyApplication.kt
```

---

## Threading Model

### Kotlin (Coroutines)

```kotlin
class OneSignalManager @Inject constructor(
    private val appContext: Context,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) {
    suspend fun initialize(appId: String) = withContext(ioDispatcher) {
        // Set log level for debugging (remove in production)
        OneSignal.Debug.logLevel = LogLevel.VERBOSE
        // Initialize OneSignal
        OneSignal.initWithContext(appContext, appId)
    }
    
    suspend fun login(externalId: String) = withContext(ioDispatcher) {
        OneSignal.login(externalId)
    }
}
```

### Java (Executors)

```java
public class OneSignalManager {
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    
    public void initialize(Context context, String appId) {
        executor.execute(() -> {
            // Set log level for debugging (remove in production)
            OneSignal.getDebug().setLogLevel(LogLevel.VERBOSE);
            // Initialize OneSignal
            OneSignal.initWithContext(context, appId);
        });
    }
}
```

---

## Code Examples

### Dependency (build.gradle.kts)

```kotlin
dependencies {
    implementation("com.onesignal:OneSignal:[5.0.0, 5.99.99]")
}
```

### Dependency (build.gradle)

```groovy
dependencies {
    implementation 'com.onesignal:OneSignal:[5.0.0, 5.99.99]'
}
```

### Centralized Manager (Kotlin)

Create a singleton manager that wraps all OneSignal SDK calls:

```kotlin
@Singleton
class OneSignalManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var isInitialized = false
    
    suspend fun initialize(appId: String) = withContext(Dispatchers.IO) {
        if (isInitialized) return@withContext
        // Set log level for debugging (remove in production)
        OneSignal.Debug.logLevel = LogLevel.VERBOSE
        // Initialize OneSignal
        OneSignal.initWithContext(context, appId)
        isInitialized = true
    }
    
    suspend fun login(externalId: String) = withContext(Dispatchers.IO) {
        OneSignal.login(externalId)
    }
    
    suspend fun logout() = withContext(Dispatchers.IO) {
        OneSignal.logout()
    }
    
    suspend fun setEmail(email: String) = withContext(Dispatchers.IO) {
        OneSignal.User.addEmail(email)
    }
    
    suspend fun setSmsNumber(number: String) = withContext(Dispatchers.IO) {
        OneSignal.User.addSms(number)
    }
    
    suspend fun setTag(key: String, value: String) = withContext(Dispatchers.IO) {
        OneSignal.User.addTag(key, value)
    }
    
    fun setLogLevel(level: LogLevel) {
        OneSignal.Debug.logLevel = level
    }
}
```

### ViewModel (Kotlin)

Initialize OneSignal from a ViewModel on a background thread:

```kotlin
@HiltViewModel
class MainViewModel @Inject constructor(
    private val oneSignalManager: OneSignalManager
) : ViewModel() {
    
    init {
        initializeOneSignal()
    }
    
    private fun initializeOneSignal() {
        viewModelScope.launch {
            // Runs on background thread via Dispatchers.IO in manager
            oneSignalManager.setLogLevel(LogLevel.VERBOSE) // Debug only
            oneSignalManager.initialize("YOUR_ONESIGNAL_APP_ID")
        }
    }
    
    fun login(externalId: String) {
        viewModelScope.launch {
            oneSignalManager.login(externalId)
        }
    }
    
    fun logout() {
        viewModelScope.launch {
            oneSignalManager.logout()
        }
    }
}
```

### Application Class (Kotlin)

Keep the Application class minimal - just set up Hilt:

```kotlin
@HiltAndroidApp
class MyApplication : Application()
```

---

## Push Subscription Verification Dialog

After completing SDK initialization, add a push subscription observer so the app can confirm that the device registered successfully.

The verification flow is:

1. Register a push subscription observer, and also check the current subscription ID immediately — on SDK 5.x the ID can already be assigned before an `Activity` attaches the observer, so reacting only to the change event would miss the transition
2. Treat the device as registered only when the subscription ID is a real, server-assigned value: non-empty and **not** prefixed with `local-` (the `local-` ID is a pre-registration placeholder the SDK assigns during `initWithContext`)
3. When registered, show the native dialog exactly once (guarded by a "shown once" flag):
   - Title: "Your OneSignal SDK integration is complete!"
   - Message: "You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications."
   - Button: "Got it"
4. On button tap, request push permission
5. If permission is granted, no additional action is required

### Kotlin

```kotlin
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AlertDialog
import com.onesignal.OneSignal
import com.onesignal.user.subscriptions.IPushSubscriptionObserver
import com.onesignal.user.subscriptions.PushSubscriptionChangedState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicBoolean

// Ensures the dialog is shown exactly once
private val dialogShown = AtomicBoolean(false)

// OneSignal stores observers weakly — keep a strong reference for the screen/app lifetime.
private var pushSubscriptionObserver: IPushSubscriptionObserver? = null

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
private fun isRegistered(subscriptionId: String?): Boolean =
    !subscriptionId.isNullOrEmpty() && !subscriptionId.startsWith("local-")

private fun maybeShowIntegrationCompleteDialog(context: Context, subscriptionId: String?) {
    if (isRegistered(subscriptionId) && dialogShown.compareAndSet(false, true)) {
        Handler(Looper.getMainLooper()).post {
            showIntegrationCompleteDialog(context)
        }
    }
}

fun setupPushSubscriptionObserver(context: Context) {
    val observer = object : IPushSubscriptionObserver {
        override fun onPushSubscriptionChange(state: PushSubscriptionChangedState) {
            maybeShowIntegrationCompleteDialog(context, state.current.id)
        }
    }
    pushSubscriptionObserver = observer
    OneSignal.User.pushSubscription.addObserver(observer)

    // The ID may already be server-assigned before the observer attaches,
    // so evaluate the current value immediately as well.
    maybeShowIntegrationCompleteDialog(context, OneSignal.User.pushSubscription.id)
}

fun showIntegrationCompleteDialog(context: Context) {
    AlertDialog.Builder(context)
        .setTitle("Your OneSignal SDK integration is complete!")
        .setMessage(
            "You can now send Push Notifications & In-App Messages through OneSignal. " +
            "Tap below to enable push notifications."
        )
        .setPositiveButton("Got it") { _, _ ->
            requestPushPermission()
        }
        .setCancelable(false)
        .show()
}

fun requestPushPermission() {
    CoroutineScope(Dispatchers.Main).launch {
        OneSignal.Notifications.requestPermission(true)
    }
}
```

### Java

```java
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import androidx.appcompat.app.AlertDialog;
import com.onesignal.OneSignal;
import com.onesignal.user.subscriptions.IPushSubscriptionObserver;
import com.onesignal.user.subscriptions.PushSubscriptionChangedState;
import java.util.concurrent.atomic.AtomicBoolean;

// Ensures the dialog is shown exactly once
private static final AtomicBoolean dialogShown = new AtomicBoolean(false);

// OneSignal stores observers weakly — keep a strong reference for the screen/app lifetime.
private static IPushSubscriptionObserver pushSubscriptionObserver;

// A real, server-assigned subscription ID is non-empty and not the local- placeholder
private static boolean isRegistered(String subscriptionId) {
    return subscriptionId != null && !subscriptionId.isEmpty() && !subscriptionId.startsWith("local-");
}

private static void maybeShowIntegrationCompleteDialog(Context context, String subscriptionId) {
    if (isRegistered(subscriptionId) && dialogShown.compareAndSet(false, true)) {
        new Handler(Looper.getMainLooper()).post(() -> {
            showIntegrationCompleteDialog(context);
        });
    }
}

public static void setupPushSubscriptionObserver(Context context) {
    IPushSubscriptionObserver observer = new IPushSubscriptionObserver() {
        @Override
        public void onPushSubscriptionChange(PushSubscriptionChangedState state) {
            maybeShowIntegrationCompleteDialog(context, state.getCurrent().getId());
        }
    };
    pushSubscriptionObserver = observer;
    OneSignal.getUser().getPushSubscription().addObserver(observer);

    // The ID may already be server-assigned before the observer attaches,
    // so evaluate the current value immediately as well.
    maybeShowIntegrationCompleteDialog(context, OneSignal.getUser().getPushSubscription().getId());
}

public static void showIntegrationCompleteDialog(Context context) {
    new AlertDialog.Builder(context)
        .setTitle("Your OneSignal SDK integration is complete!")
        .setMessage(
            "You can now send Push Notifications & In-App Messages through OneSignal. " +
            "Tap below to enable push notifications."
        )
        .setPositiveButton("Got it", (dialog, which) -> {
            OneSignal.getNotifications().requestPermission(true, result -> {});
        })
        .setCancelable(false)
        .show();
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Push not received | Check notification permission and that the App ID matches the project; confirm internet connectivity |
| Permission denied | Ensure `POST_NOTIFICATIONS` is requested on Android 13+ |
| Initialization failed | Verify App ID is correct and internet permission is granted |
| ProGuard issues | Check OneSignal rules are not being stripped |
