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

### Application Class (Kotlin)

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize OneSignal
        OneSignal.initWithContext(this, "YOUR_ONESIGNAL_APP_ID")
        
        // Set log level for debugging (remove in production)
        OneSignal.Debug.logLevel = LogLevel.VERBOSE
        
        // Request notification permission (Android 13+)
        CoroutineScope(Dispatchers.IO).launch {
            OneSignal.Notifications.requestPermission(true)
        }
    }
}
```

### Centralized Manager (Kotlin)

```kotlin
@Singleton
class OneSignalManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    fun initialize(appId: String) {
        OneSignal.initWithContext(context, appId)
    }
    
    fun login(externalId: String) {
        OneSignal.login(externalId)
    }
    
    fun logout() {
        OneSignal.logout()
    }
    
    fun setEmail(email: String) {
        OneSignal.User.addEmail(email)
    }
    
    fun setSmsNumber(number: String) {
        OneSignal.User.addSms(number)
    }
    
    fun setTag(key: String, value: String) {
        OneSignal.User.addTag(key, value)
    }
    
    suspend fun requestPermission(): Boolean {
        return withContext(Dispatchers.IO) {
            OneSignal.Notifications.requestPermission(true)
        }
    }
    
    fun setLogLevel(level: LogLevel) {
        OneSignal.Debug.logLevel = level
    }
}
```

---

## Demo Welcome View (Material Design 3)

When using the demo App ID, create this view:

### WelcomeFragment.kt

```kotlin
@AndroidEntryPoint
class WelcomeFragment : Fragment() {
    
    private var _binding: FragmentWelcomeBinding? = null
    private val binding get() = _binding!!
    
    @Inject lateinit var oneSignalManager: OneSignalManager
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentWelcomeBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupValidation()
        setupSubmitButton()
    }
    
    private fun setupValidation() {
        binding.emailInput.addTextChangedListener { validateForm() }
        binding.phoneInput.addTextChangedListener { validateForm() }
    }
    
    private fun validateForm() {
        val email = binding.emailInput.text.toString()
        val phone = binding.phoneInput.text.toString()
        
        val emailValid = email.matches(Regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"))
        val phoneValid = phone.matches(Regex("^\\+[1-9]\\d{9,14}$"))
        
        binding.emailInputLayout.error = if (email.isNotEmpty() && !emailValid) "Invalid email" else null
        binding.phoneInputLayout.error = if (phone.isNotEmpty() && !phoneValid) "Use format: +1234567890" else null
        
        binding.submitButton.isEnabled = emailValid && phoneValid
    }
    
    private fun setupSubmitButton() {
        binding.submitButton.setOnClickListener {
            submitForm()
        }
    }
    
    private fun submitForm() {
        val email = binding.emailInput.text.toString()
        val phone = binding.phoneInput.text.toString()
        
        binding.submitButton.isEnabled = false
        binding.progressIndicator.visibility = View.VISIBLE
        
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    oneSignalManager.setEmail(email)
                    oneSignalManager.setSmsNumber(phone)
                    oneSignalManager.setTag("demo_user", "true")
                    oneSignalManager.setTag("welcome_sent", System.currentTimeMillis().toString())
                }
                showSuccess()
            } catch (e: Exception) {
                showError(e.message ?: "Unknown error")
            }
        }
    }
    
    private fun showSuccess() {
        binding.formContainer.visibility = View.GONE
        binding.successContainer.visibility = View.VISIBLE
    }
    
    private fun showError(message: String) {
        binding.submitButton.isEnabled = true
        binding.progressIndicator.visibility = View.GONE
        Snackbar.make(binding.root, message, Snackbar.LENGTH_LONG).show()
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
```

### fragment_welcome.xml (Material Design 3)

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="24dp">

    <LinearLayout
        android:id="@+id/formContainer"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent">

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="OneSignal Integration Complete!"
            android:textAppearance="?attr/textAppearanceHeadlineMedium"
            android:textAlignment="center"
            android:layout_marginBottom="8dp" />

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Enter your details to receive a welcome message"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            android:textAlignment="center"
            android:layout_marginBottom="32dp" />

        <com.google.android.material.textfield.TextInputLayout
            android:id="@+id/emailInputLayout"
            style="@style/Widget.Material3.TextInputLayout.OutlinedBox"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:hint="Email Address"
            android:layout_marginBottom="16dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/emailInput"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:inputType="textEmailAddress" />
        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:id="@+id/phoneInputLayout"
            style="@style/Widget.Material3.TextInputLayout.OutlinedBox"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:hint="Phone Number"
            android:layout_marginBottom="24dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/phoneInput"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:inputType="phone" />
        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.progressindicator.LinearProgressIndicator
            android:id="@+id/progressIndicator"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:indeterminate="true"
            android:visibility="gone"
            android:layout_marginBottom="16dp" />

        <com.google.android.material.button.MaterialButton
            android:id="@+id/submitButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Send Welcome Message"
            android:enabled="false" />
    </LinearLayout>

    <LinearLayout
        android:id="@+id/successContainer"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:visibility="gone"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent">

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="✓"
            android:textSize="64sp"
            android:textAlignment="center"
            android:textColor="?attr/colorPrimary"
            android:layout_marginBottom="16dp" />

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Success!"
            android:textAppearance="?attr/textAppearanceHeadlineMedium"
            android:textAlignment="center"
            android:layout_marginBottom="8dp" />

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Check your email and phone for a welcome message!"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            android:textAlignment="center" />
    </LinearLayout>
</androidx.constraintlayout.widget.ConstraintLayout>
```

---

## Testing

### Unit Test Example

```kotlin
@Test
fun `OneSignalManager sets email correctly`() = runTest {
    val mockOneSignal = mockk<OneSignal>(relaxed = true)
    val manager = OneSignalManager(context)
    
    manager.setEmail("test@example.com")
    
    verify { OneSignal.User.addEmail("test@example.com") }
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
