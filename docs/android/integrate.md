# Android Platform Integration

## Official Documentation

* [OneSignal Android SDK Setup](https://documentation.onesignal.com/docs/android-sdk-setup)
* [Android SDK API Reference](https://documentation.onesignal.com/docs/android-sdk-api-reference)
* [Android Firebase credentials](https://documentation.onesignal.com/docs/en/android-firebase-credentials)
* [Notification icons](https://documentation.onesignal.com/docs/en/notification-icons)
* [GitHub Repository](https://github.com/OneSignal/OneSignal-Android-SDK)

If this file and the official [Android SDK setup](https://documentation.onesignal.com/docs/en/android-sdk-setup) page disagree, follow the official page.

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Permissions

- [ ] `INTERNET` permission in `AndroidManifest.xml`
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```
- [ ] `POST_NOTIFICATIONS` permission for Android 13+ (SDK handles this, but verify it's not blocked)
- [ ] **Open the app `AndroidManifest.xml` and inspect the `<application>` tag.** If it has `tools:node="replace"`, **stop and warn the user before continuing.** That merger marker wipes library-merged components. OneSignal's `PermissionsActivity` never reaches the merged manifest, and the notification permission flow crashes with `ActivityNotFoundException`.
  **Fix:** remove `tools:node="replace"`. If they only need to override one attribute (theme, label, icon), use `tools:replace="android:theme"` (or that attribute) instead. Do not add `tools:node="replace"` yourself. After the next build, confirm `com.onesignal.core.activities.PermissionsActivity` is in `app/build/intermediates/merged_manifests`.

### Build Configuration

- [ ] Minimum Android API (`minSdk`) is 23 or higher (Android 6.0+). API 31+ (Android 12+) is recommended.
- [ ] Note the project's Android Gradle Plugin (AGP) version in the Step 1 readiness picture. Don't change the AGP, Gradle, or Kotlin versions; OneSignal doesn't require it, and command-line builds can pass even when Android Studio can't open the project.
- [ ] In the Changes Summary, tell the developer to open the project in Android Studio and run **File → Sync Project with Gradle Files**. If Android Studio reports that the project uses an incompatible version of the Android Gradle plugin, the recommended fix is to **update Android Studio**. The alternative is to lower AGP to the newest version their Android Studio supports. Ask before changing AGP.

### Firebase Configuration

Follow **Android Firebase Configuration** in the shared guidelines (rules, the Step 1 question, and handling the answer). Android specifics, from the official [Android Firebase credentials](https://documentation.onesignal.com/docs/en/android-firebase-credentials) page:

- [ ] Expected location: `app/google-services.json`. Takes effect from `com.onesignal:OneSignal` 5.11.0. If the project already pins OneSignal below 5.11.0 and the developer doesn't want to upgrade, skip this section.
- [ ] `google()` is listed under `pluginManagement { repositories }` in `settings.gradle` or `settings.gradle.kts`. Otherwise the build fails with `Plugin [id: 'com.google.gms.google-services'] was not found`.
- [ ] The `com.google.gms.google-services` Gradle plugin is declared in the project-level Gradle file (`apply false`), or in the version catalog if the project uses one, and applied in the app-level Gradle file. See **Google Services plugin** under Code Examples.
- [ ] Only apply the plugin once `google-services.json` is present. Applying it without the file fails the build with `File google-services.json is missing`.
- [ ] Confirm the file took effect, as the official page shows:
  ```bash
  ./gradlew :app:processDebugGoogleServices
  grep -r "google_app_id\|project_id" app/build/generated/res/
  ```
  If `google_app_id` and `project_id` appear, it worked. If neither appears, the plugin isn't applied.
- [ ] After the build, check the merged manifest (`app/build/intermediates/merged_manifests`) for `firebase_messaging_installation_id_enabled`. If its merged `android:value` is boolean `true` (often set by another SDK through manifest merging), the Firebase configuration is **mandatory**, and `firebase-messaging` must be 25.1.2 or later.

### ProGuard/R8 (if minification is enabled)

- [ ] OneSignal ProGuard rules are included (SDK usually handles this automatically)
- [ ] Test release builds to ensure nothing is stripped incorrectly

### Initialization

- [ ] OneSignal is initialized in the `Application` class's `onCreate()`. Create an `Application` class if the app doesn't have one, and register it with `android:name` on the `<application>` tag in `AndroidManifest.xml`.
- [ ] Do NOT initialize in an `Activity` (such as `MainActivity`) or a ViewModel. Those may not run on cold starts from notifications or deep links.
- [ ] `initWithContext` is called directly in `onCreate()`, as in the official setup guide, before any other OneSignal call. See **Application Class** under Code Examples.

### Notification Icons (Recommended)

- [ ] Don't create icon files. In the Changes Summary, recommend that the developer add a small notification icon named `ic_stat_onesignal_default`. Without one, notifications show a default bell icon. Link to https://documentation.onesignal.com/docs/en/notification-icons.

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

Call `initWithContext` directly in `Application.onCreate()`, as the official setup guide does. Don't move it to a background thread, coroutine, or executor: code that touches OneSignal before initialization finishes can fail. The permission request is a `suspend` function: run it in a coroutine in Kotlin, or pass `Continue.none()` in Java.

---

## Code Examples

### Dependency (build.gradle.kts)

```kotlin
dependencies {
    implementation("com.onesignal:OneSignal:[5.6.1, 5.99.99]")
}
```

### Dependency (build.gradle)

```groovy
dependencies {
    implementation 'com.onesignal:OneSignal:[5.6.1, 5.99.99]'
}
```

Use this dependency line exactly as the official setup guide shows it. On Android it replaces the exact-version pin described in Step 2 of the shared guidelines. The range resolves to the newest 5.x release at build time. Report the resolved version in the Changes Summary (for example, from `./gradlew :app:dependencies`).

### Google Services plugin

Only add this when `google-services.json` is in `app/` (see **Firebase Configuration** in the Pre-Flight Checklist). Versions follow the official [Android Firebase credentials](https://documentation.onesignal.com/docs/en/android-firebase-credentials) page; the range keeps the project on the latest 4.x plugin.

Project-level `build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "[4.4.2, 4.99.99]" apply false
}
```

Project-level `build.gradle` (Groovy):

```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:[4.4.2, 4.99.99]'
    }
}
```

With a version catalog, declare the version in `gradle/libs.versions.toml` instead, and use `alias(libs.plugins.google.services) apply false` in the project-level file:

```toml
[versions]
google-services = "[4.4.2, 4.99.99]"

[plugins]
google-services = { id = "com.google.gms.google-services", version.ref = "google-services" }
```

App-level `app/build.gradle.kts` (use `alias(libs.plugins.google.services)` with a version catalog):

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

App-level `app/build.gradle` (Groovy):

```groovy
apply plugin: 'com.google.gms.google-services'
```

### Centralized Manager (Kotlin)

Wraps every OneSignal call. Initialization only: no login, email, SMS, or tag methods (see **Scope: initialization only** in the shared guidelines).

```kotlin
object OneSignalManager {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var isInitialized = false

    /** Call from Application.onCreate(), before any other OneSignal call. */
    fun initialize(context: Context, appId: String) {
        if (isInitialized) return
        // Enable verbose logging to debug issues (remove in production)
        OneSignal.Debug.logLevel = LogLevel.VERBOSE
        OneSignal.initWithContext(context, appId)
        isInitialized = true
    }

    /** Shows the push permission prompt. fallbackToSettings = false, as in the official guide. */
    fun requestPushPermission() {
        scope.launch {
            OneSignal.Notifications.requestPermission(false)
        }
    }

    fun setLogLevel(level: LogLevel) {
        OneSignal.Debug.logLevel = level
    }
}
```

With Hilt, make it a `@Singleton` class that takes `@ApplicationContext context: Context` in its constructor and drops the `context` parameter from `initialize`.

### Centralized Manager (Java)

```java
public final class OneSignalManager {
    private OneSignalManager() {}

    /** Call from Application.onCreate(), before any other OneSignal call. */
    public static void initialize(Context context, String appId) {
        // Enable verbose logging to debug issues (remove in production)
        OneSignal.getDebug().setLogLevel(LogLevel.VERBOSE);
        OneSignal.initWithContext(context, appId);
    }

    /** fallbackToSettings = false, as in the official guide. */
    public static void requestPushPermission() {
        OneSignal.getNotifications().requestPermission(false, Continue.none());
    }
}
```

### Application Class

Initialize OneSignal in `onCreate()` and request push permission right after, following the official setup guide. Route both calls through the wrapper. Replace `YOUR_APP_ID` with the App ID from Step 1.

Kotlin:

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        OneSignalManager.initialize(this, "YOUR_APP_ID")
        OneSignalManager.requestPushPermission()
    }
}
```

Kotlin with Hilt:

```kotlin
@HiltAndroidApp
class MyApplication : Application() {
    @Inject lateinit var oneSignalManager: OneSignalManager

    override fun onCreate() {
        super.onCreate() // Hilt injects fields here
        oneSignalManager.initialize("YOUR_APP_ID")
        oneSignalManager.requestPushPermission()
    }
}
```

Java:

```java
public class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        OneSignalManager.initialize(this, "YOUR_APP_ID");
        OneSignalManager.requestPushPermission();
    }
}
```

Register it in `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApplication"
    ... >
```

### Identifying users (reference only)

**Not part of the initial integration.** Don't add login, email, SMS, or tag calls during setup (see **Scope: initialization only** in the shared guidelines). This section applies only if the developer later asks you to identify users, and its rules still hold then.

On SDK 5.11.0 and later this is the method to reach for. It sends the external ID together
with the user's email, SMS number, tags, and aliases as a single Create User request, and it
returns a `OneSignalResult<LoginData>` so the caller can see whether it worked. Build the
profile with `OneSignalUserProfile.builder()`; every field is optional.

Use identity-only `login(externalId)` only when you have nothing but the user's ID at
sign-in, then add the rest with `addEmail()` / `addSms()` / `addTag()` afterward.

Rules that matter when writing the call:

* It is a `suspend` function. Call it from a coroutine in Kotlin, or pass `Continue.with` in Java.
* `setSms()` requires E.164 with the leading `+` (for example `+15551234567`). A malformed
  number returns `INVALID_ARGUMENT` and sends no request.
* `setEmailEnabled(true)` / `setSmsEnabled(true)` subscribe that address, and `false`
  unsubscribes it. Leave the flag unset to send no status, which subscribes a new address and
  leaves an existing address's status unchanged. Setting the flag is the only way to
  resubscribe an address that previously opted out, which `addEmail()` and `addSms()` cannot do.
* **Do not key the flag off whether you have the address.** Having a user's email is not
  consent, and `true` resubscribes someone who opted out. Set it only from a real signal, such
  as a checkbox the user just ticked. If the app has no such signal, leave it unset.
* Do not pass an email or phone number the user typed without verifying it. An address that
  already belongs to another user moves to whoever logs in. Pair it with Identity Verification.
* Ordering no longer matters for anything in the profile, because it ships inside the login
  request. The "login before tags/email/sms" rule still applies to the granular methods.

---

## Push Permission Request

Follow the official setup guide: request push permission in `Application.onCreate()`, right after initialization, with `OneSignalManager.requestPushPermission()` (see **Application Class** above). Do **not** add a verification dialog on Android, and don't request permission anywhere else.

In the Changes Summary, mention the official guide's advice: in production, consider prompting with an in-app message instead, for better opt-in rates.

If the developer skipped the App ID, still add the permission request, and include this alert at the top of the Changes Summary, next to the App ID reminder:

> **The app will show the push permission prompt at launch, but the device won't register with OneSignal until you set your App ID.** Users who accept now won't be reachable until a build with your real App ID ships.

---

## Verification

Give the developer these steps in the Changes Summary, following the official guide:

1. Open the project in Android Studio, run **File → Sync Project with Gradle Files**, and launch the app on a device or emulator with Google Play services.
2. In the OneSignal dashboard, open **Audience → Users & subscriptions → Subscriptions**. The new Subscription shows **Never Subscribed**.
3. Accept the permission prompt in the app.
4. Refresh the dashboard. The status changes to **Subscribed**.
5. Send a test push. This needs FCM credentials in the OneSignal dashboard (see **After setup: FCM credentials in OneSignal** in the shared guidelines).

Do **not** clear app data (`adb shell pm clear …`), wipe the emulator, or uninstall/reinstall just to re-check — that creates a second OneSignal subscription. Rebuild/relaunch while preserving app storage. See shared guidelines: **Verification without duplicate subscriptions**.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Push not received | Check notification permission and that the App ID matches the project; confirm internet connectivity |
| Duplicate subscriptions after re-test | Do not clear app data or uninstall/reinstall to re-verify — relaunch preserving storage (see shared guidelines) |
| Permission denied | Ensure `POST_NOTIFICATIONS` is requested on Android 13+ |
| `ActivityNotFoundException` for `PermissionsActivity` | Open the app `AndroidManifest.xml`. If `<application>` has `tools:node="replace"`, warn the user: that drops OneSignal's `PermissionsActivity` and crashes the notification permission flow. Remove `tools:node="replace"`. Override one attribute with `tools:replace` instead. Confirm `com.onesignal.core.activities.PermissionsActivity` is in the merged manifest. |
| Initialization failed | Verify App ID is correct and internet permission is granted |
| ProGuard issues | Check OneSignal rules are not being stripped |
| Android Studio: "The project is using an incompatible version of the Android Gradle plugin" | The project's AGP is newer than the developer's Android Studio supports. Recommend updating Android Studio. The alternative is to lower AGP to the newest supported version, but ask first and don't change it as part of the OneSignal integration |
| Build fails after applying the Google Services plugin | `google-services.json` is missing from `app/`, or its `package_name` doesn't match the `applicationId`. Ask the developer for the correct file; never generate one |
| Subscription status `-6` | The Firebase project in `google-services.json` is not the project whose Service Account is uploaded to OneSignal. Use files from the same Firebase project |
| Subscription status `-32` | Firebase Installation ID registration is enabled, but there is no default `FirebaseApp`: `google-services.json` is missing or the Google Services plugin isn't applied. Add the Firebase configuration |
| Subscription status `-33` | Firebase Installation ID registration is enabled, but `firebase-messaging` is older than 25.1.2 or was stripped by R8. Upgrade `firebase-messaging` |
