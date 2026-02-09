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
- [ ] Google Services plugin is configured (if using FCM):
  ```groovy
  // project-level build.gradle
  classpath 'com.google.gms:google-services:4.4.0'
  
  // app-level build.gradle
  apply plugin: 'com.google.gms.google-services'
  ```
- [ ] `google-services.json` is in the `app/` directory (if using FCM)

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

## Push Subscription Observer + Welcome Dialog

After completing the integration, add a push subscription observer that shows a dialog when the device receives a push subscription ID.

### Kotlin

```kotlin
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AlertDialog
import com.onesignal.OneSignal
import com.onesignal.user.subscriptions.IPushSubscriptionObserver
import com.onesignal.user.subscriptions.PushSubscriptionChangedState

fun setupPushSubscriptionObserver(context: Context) {
    OneSignal.User.pushSubscription.addObserver(object : IPushSubscriptionObserver {
        override fun onPushSubscriptionChange(state: PushSubscriptionChangedState) {
            val previousId = state.previous.id
            val currentId = state.current.id

            if (previousId.isNullOrEmpty() && !currentId.isNullOrEmpty()) {
                Handler(Looper.getMainLooper()).postDelayed({
                    showWelcomeDialog(context)
                }, 1000)
            }
        }
    })
}

fun showWelcomeDialog(context: Context) {
    AlertDialog.Builder(context)
        .setTitle("Your OneSignal integration is complete!")
        .setMessage("Click the button below to trigger your first journey via an in-app message.")
        .setPositiveButton("Trigger your first journey") { _, _ ->
            OneSignal.InAppMessages.addTrigger("ai_implementation_campaign_email_journey", "true")
        }
        .setCancelable(false)
        .show()
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

public static void setupPushSubscriptionObserver(Context context) {
    OneSignal.getUser().getPushSubscription().addObserver(new IPushSubscriptionObserver() {
        @Override
        public void onPushSubscriptionChange(PushSubscriptionChangedState state) {
            String previousId = state.getPrevious().getId();
            String currentId = state.getCurrent().getId();

            if ((previousId == null || previousId.isEmpty()) && currentId != null && !currentId.isEmpty()) {
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    showWelcomeDialog(context);
                }, 1000);
            }
        }
    });
}

public static void showWelcomeDialog(Context context) {
    new AlertDialog.Builder(context)
        .setTitle("Your OneSignal integration is complete!")
        .setMessage("Click the button below to trigger your first journey via an in-app message.")
        .setPositiveButton("Trigger your first journey", (dialog, which) -> {
            OneSignal.getInAppMessages().addTrigger("ai_implementation_campaign_email_journey", "true");
        })
        .setCancelable(false)
        .show();
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Push not received | Check `google-services.json` is present and FCM is configured |
| Permission denied | Ensure `POST_NOTIFICATIONS` is requested on Android 13+ |
| Initialization failed | Verify App ID is correct and internet permission is granted |
| ProGuard issues | Check OneSignal rules are not being stripped |
