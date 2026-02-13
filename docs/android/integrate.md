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

## Push Subscription Observer + Welcome Dialog + Send Notification Flow

After completing the integration, add a push subscription observer that shows a dialog when the device receives a push subscription ID. The full flow is:

1. Push subscription observer fires → show welcome dialog with IAM trigger button
2. On click → trigger the email IAM
3. IAM lifecycle listener detects when email IAM is dismissed
4. On dismiss → prompt for push permission
5. If allowed → show a second dialog with a text field → send a push notification to self via REST API
6. If denied → end

### Kotlin

```kotlin
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import com.onesignal.OneSignal
import com.onesignal.inAppMessages.IInAppMessageDidDismissEvent
import com.onesignal.inAppMessages.IInAppMessageDidDisplayEvent
import com.onesignal.inAppMessages.IInAppMessageLifecycleListener
import com.onesignal.inAppMessages.IInAppMessageWillDismissEvent
import com.onesignal.inAppMessages.IInAppMessageWillDisplayEvent
import com.onesignal.user.subscriptions.IPushSubscriptionObserver
import com.onesignal.user.subscriptions.PushSubscriptionChangedState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.StandardCharsets

private const val APP_ID = "YOUR_ONESIGNAL_APP_ID"

// Step 1: Register push subscription observer after OneSignal is initialized
fun setupPushSubscriptionObserver(context: Context) {
    OneSignal.User.pushSubscription.addObserver(object : IPushSubscriptionObserver {
        override fun onPushSubscriptionChange(state: PushSubscriptionChangedState) {
            val previousId = state.previous.id
            val currentId = state.current.id

            if (previousId.isNullOrEmpty() && !currentId.isNullOrEmpty()) {
                Handler(Looper.getMainLooper()).post {
                    showWelcomeDialog(context)
                }
            }
        }
    })
}

// Step 2: Show welcome dialog with IAM trigger button
fun showWelcomeDialog(context: Context) {
    AlertDialog.Builder(context)
        .setTitle("Your OneSignal integration is complete!")
        .setMessage("Click the button below to trigger your first journey via an in-app message.")
        .setPositiveButton("Trigger your first journey") { _, _ ->
            OneSignal.InAppMessages.addTrigger("ai_implementation_campaign_email_journey", "true")
            setupIAMDismissListener(context)
        }
        .setCancelable(false)
        .show()
}

// Step 3: Listen for IAM dismissal
fun setupIAMDismissListener(context: Context) {
    OneSignal.InAppMessages.addLifecycleListener(object : IInAppMessageLifecycleListener {
        override fun onWillDisplay(event: IInAppMessageWillDisplayEvent) {}
        override fun onDidDisplay(event: IInAppMessageDidDisplayEvent) {}
        override fun onWillDismiss(event: IInAppMessageWillDismissEvent) {}
        override fun onDidDismiss(event: IInAppMessageDidDismissEvent) {
            OneSignal.InAppMessages.removeLifecycleListener(this)
            promptForPushPermission(context)
        }
    })
}

// Step 4: Prompt for push permission after IAM is dismissed
// NOTE: requestPermission is a suspend function in SDK 5.x — it must be called
// from a coroutine. Use lifecycleScope.launch when inside an Activity/Fragment.
fun promptForPushPermission(context: Context) {
    CoroutineScope(Dispatchers.Main).launch {
        val granted = OneSignal.Notifications.requestPermission(true)
        if (granted) {
            showSendNotificationDialog(context)
        }
    }
}

// Step 5: Show dialog with text field to compose a notification message
fun showSendNotificationDialog(context: Context) {
    val messageInput = EditText(context).apply {
        hint = "Enter your notification message"
    }

    AlertDialog.Builder(context)
        .setTitle("Send a Push Notification")
        .setMessage("Type a message below and tap Send to receive a push notification on this device.")
        .setView(messageInput)
        .setPositiveButton("Send") { _, _ ->
            val message = messageInput.text.toString()
            if (message.isNotEmpty()) {
                sendPushNotification(context, message)
            }
        }
        .setNegativeButton("Cancel", null)
        .setCancelable(false)
        .show()
}

// Step 6: Send push notification to self via OneSignal REST API
fun sendPushNotification(context: Context, message: String) {
    Thread {
        try {
            val subscriptionId = OneSignal.User.pushSubscription.id
            if (subscriptionId.isNullOrEmpty()) return@Thread

            val json = JSONObject().apply {
                put("app_id", APP_ID)
                put("contents", JSONObject().put("en", message))
                put("headings", JSONObject().put("en", "OneSignal Demo"))
                put("include_subscription_ids", JSONArray().put(subscriptionId))
            }

            val url = URL("https://api.onesignal.com/notifications")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            conn.setRequestProperty("Accept", "application/json")
            conn.doOutput = true

            conn.outputStream.use { it.write(json.toString().toByteArray(StandardCharsets.UTF_8)) }

            val responseCode = conn.responseCode
            Handler(Looper.getMainLooper()).post {
                if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                    Toast.makeText(context, "Notification sent!", Toast.LENGTH_SHORT).show()
                } else {
                    Toast.makeText(context, "Failed to send notification.", Toast.LENGTH_SHORT).show()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }.start()
}
```

### Java

```java
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import com.onesignal.OneSignal;
import com.onesignal.inAppMessages.IInAppMessageDidDismissEvent;
import com.onesignal.inAppMessages.IInAppMessageDidDisplayEvent;
import com.onesignal.inAppMessages.IInAppMessageLifecycleListener;
import com.onesignal.inAppMessages.IInAppMessageWillDismissEvent;
import com.onesignal.inAppMessages.IInAppMessageWillDisplayEvent;
import com.onesignal.user.subscriptions.IPushSubscriptionObserver;
import com.onesignal.user.subscriptions.PushSubscriptionChangedState;
import org.json.JSONArray;
import org.json.JSONObject;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

private static final String APP_ID = "YOUR_ONESIGNAL_APP_ID";

// Step 1: Register push subscription observer after OneSignal is initialized
public static void setupPushSubscriptionObserver(Context context) {
    OneSignal.getUser().getPushSubscription().addObserver(new IPushSubscriptionObserver() {
        @Override
        public void onPushSubscriptionChange(PushSubscriptionChangedState state) {
            String previousId = state.getPrevious().getId();
            String currentId = state.getCurrent().getId();

            if ((previousId == null || previousId.isEmpty()) && currentId != null && !currentId.isEmpty()) {
                new Handler(Looper.getMainLooper()).post(() -> {
                    showWelcomeDialog(context);
                });
            }
        }
    });
}

// Step 2: Show welcome dialog with IAM trigger button
public static void showWelcomeDialog(Context context) {
    new AlertDialog.Builder(context)
        .setTitle("Your OneSignal integration is complete!")
        .setMessage("Click the button below to trigger your first journey via an in-app message.")
        .setPositiveButton("Trigger your first journey", (dialog, which) -> {
            OneSignal.getInAppMessages().addTrigger("ai_implementation_campaign_email_journey", "true");
            setupIAMDismissListener(context);
        })
        .setCancelable(false)
        .show();
}

// Step 3: Listen for IAM dismissal
public static void setupIAMDismissListener(Context context) {
    IInAppMessageLifecycleListener listener = new IInAppMessageLifecycleListener() {
        @Override public void onWillDisplay(IInAppMessageWillDisplayEvent event) {}
        @Override public void onDidDisplay(IInAppMessageDidDisplayEvent event) {}
        @Override public void onWillDismiss(IInAppMessageWillDismissEvent event) {}
        @Override
        public void onDidDismiss(IInAppMessageDidDismissEvent event) {
            OneSignal.getInAppMessages().removeLifecycleListener(this);
            promptForPushPermission(context);
        }
    };
    OneSignal.getInAppMessages().addLifecycleListener(listener);
}

// Step 4: Prompt for push permission after IAM is dismissed
public static void promptForPushPermission(Context context) {
    OneSignal.getNotifications().requestPermission(true, result -> {
        if (result) {
            new Handler(Looper.getMainLooper()).post(() -> {
                showSendNotificationDialog(context);
            });
        }
    });
}

// Step 5: Show dialog with text field to compose a notification message
public static void showSendNotificationDialog(Context context) {
    EditText messageInput = new EditText(context);
    messageInput.setHint("Enter your notification message");

    new AlertDialog.Builder(context)
        .setTitle("Send a Push Notification")
        .setMessage("Type a message below and tap Send to receive a push notification on this device.")
        .setView(messageInput)
        .setPositiveButton("Send", (dialog, which) -> {
            String message = messageInput.getText().toString();
            if (!message.isEmpty()) {
                sendPushNotification(context, message);
            }
        })
        .setNegativeButton("Cancel", null)
        .setCancelable(false)
        .show();
}

// Step 6: Send push notification to self via OneSignal REST API
public static void sendPushNotification(Context context, String message) {
    new Thread(() -> {
        try {
            String subscriptionId = OneSignal.getUser().getPushSubscription().getId();
            if (subscriptionId == null || subscriptionId.isEmpty()) return;

            JSONObject json = new JSONObject();
            json.put("app_id", APP_ID);
            json.put("contents", new JSONObject().put("en", message));
            json.put("headings", new JSONObject().put("en", "OneSignal Demo"));
            json.put("include_subscription_ids", new JSONArray().put(subscriptionId));

            URL url = new URL("https://api.onesignal.com/notifications");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setRequestProperty("Accept", "application/json");
            conn.setDoOutput(true);

            byte[] outputBytes = json.toString().getBytes(StandardCharsets.UTF_8);
            conn.getOutputStream().write(outputBytes);

            int responseCode = conn.getResponseCode();
            new Handler(Looper.getMainLooper()).post(() -> {
                if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                    Toast.makeText(context, "Notification sent!", Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(context, "Failed to send notification.", Toast.LENGTH_SHORT).show();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }).start();
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
