# React Native Expo Integration Guide

## Official Documentation

* [OneSignal React Native SDK Setup](https://documentation.onesignal.com/docs/react-native-sdk-setup)
* [React Native SDK API Reference](https://documentation.onesignal.com/docs/react-native-sdk-api-reference)
* [NPM Package](https://www.npmjs.com/package/react-native-onesignal)
* [GitHub Repository](https://github.com/OneSignal/react-native-onesignal)

---

## User Prompts

Before beginning the integration, ask the user the following question:

> **Language Preference**: Do you want the integration code in JavaScript or TypeScript?

Use the user's response to determine which code examples to provide throughout the integration.

---

## Important: Development Build Required

> **Push notifications do NOT work in Expo Go.**
>
> You must create a development build to test push notifications:
> ```bash
> npx expo prebuild
> npx expo run:ios    # for iOS
> npx expo run:android # for Android
> ```
>
> Alternatively, use [EAS Build](https://docs.expo.dev/build/introduction/) for cloud-based builds.

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### Expo Configuration

- [ ] Expo SDK 49+ (recommended for best compatibility)
- [ ] `bundleIdentifier` set in `app.json` under `expo.ios`
- [ ] `package` set in `app.json` under `expo.android`
- [ ] `onesignal-expo-plugin` configured in `app.json` plugins array
- [ ] Development build created (not using Expo Go)

### OneSignal Dashboard

- [ ] OneSignal App ID obtained from dashboard
- [ ] iOS: APNs key/certificate uploaded to OneSignal dashboard
- [ ] Android: FCM Server Key configured (if using FCM)

### Initialization

- [ ] OneSignal initialized in `App.js` or `App.tsx` (root component)
- [ ] Initialize before rendering main app content

---

## Installation

Install the OneSignal SDK and Expo plugin:

```bash
npx expo install react-native-onesignal onesignal-expo-plugin
```

---

## app.json Configuration

Add the OneSignal plugin to your `app.json` (or `app.config.js`):

```json
{
  "expo": {
    "name": "YourAppName",
    "slug": "your-app-slug",
    "ios": {
      "bundleIdentifier": "com.yourcompany.yourapp"
    },
    "android": {
      "package": "com.yourcompany.yourapp"
    },
    "plugins": [
      [
        "onesignal-expo-plugin",
        {
          "mode": "development"
        }
      ]
    ]
  }
}
```

### Plugin Options

| Option | Description |
|--------|-------------|
| `mode` | Set to `"development"` for dev builds, `"production"` for release builds |
| `devTeam` | (iOS only) Your Apple Developer Team ID - required for physical device builds |
| `iPhoneDeploymentTarget` | (iOS only) Minimum iOS version, defaults to `"12.0"` |
| `smallIcons` | (Android only) Array of small notification icon paths |
| `largeIcons` | (Android only) Array of large notification icon paths |

### Example with iOS Team ID (for physical device builds):

```json
{
  "plugins": [
    [
      "onesignal-expo-plugin",
      {
        "mode": "development",
        "devTeam": "YOUR_APPLE_TEAM_ID"
      }
    ]
  ]
}
```

---

## Demo Welcome View

When using a demo App ID for testing, you can use this welcome screen to verify the integration:

### JavaScript Version (WelcomeScreen.js)

```javascript
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { OneSignal } from 'react-native-onesignal';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function WelcomeScreen() {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [errors, setErrors] = useState({});

  const isEmailValid = EMAIL_REGEX.test(email);
  const isFormValid = isEmailValid;

  const validateFields = () => {
    const newErrors = {};
    if (email && !isEmailValid) {
      newErrors.email = 'Enter a valid email address';
    }
    setErrors(newErrors);
  };

  const handleSubmit = async () => {
    if (!isFormValid) return;

    setIsLoading(true);

    try {
      OneSignal.User.addEmail(email);
      OneSignal.User.addTag('demo_user', 'true');
      OneSignal.User.addTag('welcome_sent', Date.now().toString());

      await new Promise((resolve) => setTimeout(resolve, 500));
      setShowSuccess(true);
    } catch (error) {
      console.error('Error submitting:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (showSuccess) {
    return (
      <View style={styles.successContainer}>
        <Text style={styles.checkmark}>✓</Text>
        <Text style={styles.successTitle}>Success!</Text>
        <Text style={styles.successMessage}>
          Check your email for a welcome message!
        </Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.title}>OneSignal Integration Complete!</Text>
          <Text style={styles.subtitle}>
            Enter your details to receive a welcome message
          </Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputContainer}>
            <Text style={styles.label}>Email Address</Text>
            <TextInput
              style={[styles.input, errors.email && styles.inputError]}
              value={email}
              onChangeText={setEmail}
              onBlur={validateFields}
              placeholder="you@example.com"
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
            />
            {errors.email && <Text style={styles.errorText}>{errors.email}</Text>}
          </View>

          <TouchableOpacity
            style={[styles.button, !isFormValid && styles.buttonDisabled]}
            onPress={handleSubmit}
            disabled={!isFormValid || isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Send Welcome Message</Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 24,
  },
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  form: {
    width: '100%',
  },
  inputContainer: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    backgroundColor: '#f9f9f9',
  },
  inputError: {
    borderColor: '#e74c3c',
  },
  errorText: {
    color: '#e74c3c',
    fontSize: 12,
    marginTop: 4,
  },
  button: {
    backgroundColor: '#6c5ce7',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonDisabled: {
    backgroundColor: '#bbb',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  successContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
    backgroundColor: '#fff',
  },
  checkmark: {
    fontSize: 64,
    color: '#27ae60',
    marginBottom: 16,
  },
  successTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  successMessage: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
});
```

### TypeScript Version (WelcomeScreen.tsx)

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { OneSignal } from 'react-native-onesignal';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

interface FormErrors {
  email?: string;
}

export const WelcomeScreen: React.FC = () => {
  const [email, setEmail] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [showSuccess, setShowSuccess] = useState<boolean>(false);
  const [errors, setErrors] = useState<FormErrors>({});

  const isEmailValid = EMAIL_REGEX.test(email);
  const isFormValid = isEmailValid;

  const validateFields = (): void => {
    const newErrors: FormErrors = {};
    if (email && !isEmailValid) {
      newErrors.email = 'Enter a valid email address';
    }
    setErrors(newErrors);
  };

  const handleSubmit = async (): Promise<void> => {
    if (!isFormValid) return;

    setIsLoading(true);

    try {
      OneSignal.User.addEmail(email);
      OneSignal.User.addTag('demo_user', 'true');
      OneSignal.User.addTag('welcome_sent', Date.now().toString());

      await new Promise((resolve) => setTimeout(resolve, 500));
      setShowSuccess(true);
    } catch (error) {
      console.error('Error submitting:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (showSuccess) {
    return (
      <View style={styles.successContainer}>
        <Text style={styles.checkmark}>✓</Text>
        <Text style={styles.successTitle}>Success!</Text>
        <Text style={styles.successMessage}>
          Check your email for a welcome message!
        </Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.title}>OneSignal Integration Complete!</Text>
          <Text style={styles.subtitle}>
            Enter your details to receive a welcome message
          </Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputContainer}>
            <Text style={styles.label}>Email Address</Text>
            <TextInput
              style={[styles.input, errors.email && styles.inputError]}
              value={email}
              onChangeText={setEmail}
              onBlur={validateFields}
              placeholder="you@example.com"
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
            />
            {errors.email && <Text style={styles.errorText}>{errors.email}</Text>}
          </View>

          <TouchableOpacity
            style={[styles.button, !isFormValid && styles.buttonDisabled]}
            onPress={handleSubmit}
            disabled={!isFormValid || isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Send Welcome Message</Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 24,
  },
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  form: {
    width: '100%',
  },
  inputContainer: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    backgroundColor: '#f9f9f9',
  },
  inputError: {
    borderColor: '#e74c3c',
  },
  errorText: {
    color: '#e74c3c',
    fontSize: 12,
    marginTop: 4,
  },
  button: {
    backgroundColor: '#6c5ce7',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonDisabled: {
    backgroundColor: '#bbb',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  successContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
    backgroundColor: '#fff',
  },
  checkmark: {
    fontSize: 64,
    color: '#27ae60',
    marginBottom: 16,
  },
  successTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  successMessage: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
});
```

---

## Advanced Patterns (Optional)

For larger applications, you may want to use one of these patterns:

### Context Provider Pattern

```typescript
// src/contexts/NotificationContext.tsx
import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { OneSignal, LogLevel } from 'react-native-onesignal';

interface NotificationContextType {
  isInitialized: boolean;
  hasPermission: boolean;
  requestPermission: () => Promise<boolean>;
  setUserEmail: (email: string) => void;
  setUserPhone: (phone: string) => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

interface ProviderProps {
  children: ReactNode;
  appId: string;
}

export const NotificationProvider: React.FC<ProviderProps> = ({ children, appId }) => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize(appId);
    setIsInitialized(true);

    OneSignal.Notifications.addEventListener('permissionChange', setHasPermission);

    return () => {
      OneSignal.Notifications.removeEventListener('permissionChange', setHasPermission);
    };
  }, [appId]);

  const requestPermission = async (): Promise<boolean> => {
    const granted = await OneSignal.Notifications.requestPermission(true);
    setHasPermission(granted);
    return granted;
  };

  const setUserEmail = (email: string): void => {
    OneSignal.User.addEmail(email);
  };

  const setUserPhone = (phone: string): void => {
    OneSignal.User.addSms(phone);
  };

  return (
    <NotificationContext.Provider
      value={{ isInitialized, hasPermission, requestPermission, setUserEmail, setUserPhone }}
    >
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotifications = (): NotificationContextType => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within NotificationProvider');
  }
  return context;
};
```

### Custom Hook Pattern

```typescript
// src/hooks/useOneSignal.ts
import { useEffect, useState, useCallback } from 'react';
import { OneSignal, LogLevel } from 'react-native-onesignal';

export const useOneSignal = (appId: string) => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize(appId);
    setIsInitialized(true);

    const checkPermission = async () => {
      const permission = await OneSignal.Notifications.getPermissionAsync();
      setHasPermission(permission);
    };
    checkPermission();
  }, [appId]);

  const requestPermission = useCallback(async () => {
    const granted = await OneSignal.Notifications.requestPermission(true);
    setHasPermission(granted);
    return granted;
  }, []);

  return {
    isInitialized,
    hasPermission,
    requestPermission,
  };
};
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Push notifications not working in Expo Go | Expo Go does not support push notifications. Create a development build with `npx expo prebuild` and `npx expo run:ios` or `npx expo run:android` |
| Missing `bundleIdentifier` error | Add `"bundleIdentifier": "com.yourcompany.yourapp"` under `expo.ios` in `app.json` |
| Missing `package` error | Add `"package": "com.yourcompany.yourapp"` under `expo.android` in `app.json` |
| iOS build fails with pod errors | Run `npx expo prebuild --clean` to regenerate native projects |
| Android build fails with Gradle errors | Ensure Java 17 is installed: `export JAVA_HOME="/path/to/java17"` then rebuild |
| AssetCatalogSimulatorAgent failure (Xcode 16.1) | Simplify asset catalog or restart Mac. See workaround below. |
| Build shows "0 errors" but fails | Capture stderr: `npx expo run:ios 2> error-logs.txt` and inspect the file |
| Notifications not received | Verify APNs/FCM credentials in OneSignal dashboard |
| Permission always false | Check notification settings in device Settings app |
| Module not found | Clear Metro cache: `npx expo start --clear` |

### AssetCatalogSimulatorAgent Workaround (Xcode 16.1)

If you encounter `Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn`, try this workaround:

```bash
# Backup original asset catalog
cp -r ios/[AppName]/Images.xcassets ios/[AppName]/Images.xcassets.backup

# Create minimal asset catalog
rm -rf ios/[AppName]/Images.xcassets
mkdir -p ios/[AppName]/Images.xcassets/AppIcon.appiconset

# Create minimal Contents.json
echo '{"info":{"author":"xcode","version":1}}' > ios/[AppName]/Images.xcassets/Contents.json
echo '{"images":[],"info":{"author":"xcode","version":1}}' > ios/[AppName]/Images.xcassets/AppIcon.appiconset/Contents.json

# Rebuild
npx expo run:ios
```

### Debugging Build Failures

```bash
# Capture full error output
npx expo run:ios 2> error-logs.txt

# Search for actual errors
grep -i "error:" error-logs.txt

# Or check Expo's xcodebuild log
cat .expo/xcodebuild.log | grep -A5 "error:"
```
