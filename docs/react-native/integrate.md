# React Native Platform Integration

## Official Documentation

* [OneSignal React Native SDK Setup](https://documentation.onesignal.com/docs/react-native-sdk-setup)
* [React Native SDK API Reference](https://documentation.onesignal.com/docs/react-native-sdk-api-reference)
* [NPM Package](https://www.npmjs.com/package/react-native-onesignal)
* [GitHub Repository](https://github.com/OneSignal/react-native-onesignal)

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### React Native Configuration

- [ ] React Native version 0.60+ (auto-linking supported)
- [ ] For RN < 0.60, manual linking is required

### iOS Sub-Project

- [ ] Run `npx pod-install` or `cd ios && pod install`
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes capability with Remote notifications
- [ ] Minimum deployment target iOS 11.0+
- [ ] APNs key/certificate uploaded to OneSignal dashboard

### Android Sub-Project

- [ ] `minSdkVersion` 21+ in `android/build.gradle`
- [ ] `compileSdkVersion` 33+ in `android/build.gradle`
- [ ] `google-services.json` in `android/app/` (if using FCM)
- [ ] Google Services plugin configured

### Metro Configuration

- [ ] Metro bundler can resolve native modules
- [ ] No conflicts with other push notification libraries

### Initialization

- [ ] OneSignal initialized in `App.tsx` or root component
- [ ] Initialize before rendering main app content

---

## Architecture Guidance

### Context/Provider Pattern

```
src/
├── App.tsx
├── contexts/
│   └── NotificationContext.tsx    # OneSignal provider
├── services/
│   └── oneSignalService.ts        # OneSignal wrapper
├── hooks/
│   └── useNotifications.ts        # Custom hook
└── screens/
    └── ...
```

### Redux/Zustand

```
src/
├── App.tsx
├── store/
│   └── notificationSlice.ts       # Notification state
├── services/
│   └── oneSignalService.ts
└── ...
```

### Simple/No Architecture

```
src/
├── App.tsx
├── services/
│   └── oneSignalService.ts
└── ...
```

---

## Threading Model

React Native handles JS-Native bridging automatically. OneSignal operations are async by nature.

### Async/Await Pattern

```typescript
class OneSignalService {
  async initialize(appId: string): Promise<void> {
    OneSignal.initialize(appId);
  }
  
  async requestPermission(): Promise<boolean> {
    return await OneSignal.Notifications.requestPermission(true);
  }
}
```

### Event Listeners

```typescript
// Notification events run on the JS thread
OneSignal.Notifications.addEventListener('click', (event) => {
  console.log('Notification clicked:', event.notification);
});
```

---

## Code Examples

### Installation

```bash
# npm
npm install react-native-onesignal

# yarn
yarn add react-native-onesignal

# Then install iOS pods
npx pod-install
# or
cd ios && pod install
```

### App Entry Point (App.tsx)

```typescript
import React, { useEffect } from 'react';
import { SafeAreaView, StatusBar } from 'react-native';
import { OneSignal, LogLevel } from 'react-native-onesignal';

const App: React.FC = () => {
  useEffect(() => {
    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize('YOUR_ONESIGNAL_APP_ID');
    
    // Request notification permission
    OneSignal.Notifications.requestPermission(true);
    
    // Setup notification listeners
    OneSignal.Notifications.addEventListener('click', (event) => {
      console.log('Notification clicked:', event.notification);
    });
    
    return () => {
      // Cleanup listeners if needed
      OneSignal.Notifications.removeEventListener('click');
    };
  }, []);
  
  return (
    <SafeAreaView>
      <StatusBar />
      {/* Your app content */}
    </SafeAreaView>
  );
};

export default App;
```

### Centralized Service (TypeScript)

```typescript
// src/services/oneSignalService.ts
import { OneSignal, LogLevel } from 'react-native-onesignal';

class OneSignalService {
  private static instance: OneSignalService;
  private isInitialized = false;
  
  private constructor() {}
  
  static getInstance(): OneSignalService {
    if (!OneSignalService.instance) {
      OneSignalService.instance = new OneSignalService();
    }
    return OneSignalService.instance;
  }
  
  initialize(appId: string): void {
    if (this.isInitialized) return;
    
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize(appId);
    this.isInitialized = true;
  }
  
  login(externalId: string): void {
    OneSignal.login(externalId);
  }
  
  logout(): void {
    OneSignal.logout();
  }
  
  setEmail(email: string): void {
    OneSignal.User.addEmail(email);
  }
  
  setSmsNumber(number: string): void {
    OneSignal.User.addSms(number);
  }
  
  setTag(key: string, value: string): void {
    OneSignal.User.addTag(key, value);
  }
  
  async requestPermission(): Promise<boolean> {
    return await OneSignal.Notifications.requestPermission(true);
  }
  
  setLogLevel(level: LogLevel): void {
    OneSignal.Debug.setLogLevel(level);
  }
  
  // Event listeners
  addNotificationClickListener(handler: (event: any) => void): void {
    OneSignal.Notifications.addEventListener('click', handler);
  }
  
  addNotificationForegroundListener(handler: (event: any) => void): void {
    OneSignal.Notifications.addEventListener('foregroundWillDisplay', handler);
  }
  
  removeNotificationClickListener(): void {
    OneSignal.Notifications.removeEventListener('click');
  }
}

export const oneSignalService = OneSignalService.getInstance();
```

### Context Provider

```typescript
// src/contexts/NotificationContext.tsx
import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { oneSignalService } from '../services/oneSignalService';

interface NotificationContextType {
  isPermissionGranted: boolean;
  requestPermission: () => Promise<void>;
  setUserDetails: (email: string, phone: string) => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

interface ProviderProps {
  children: ReactNode;
  appId: string;
}

export const NotificationProvider: React.FC<ProviderProps> = ({ children, appId }) => {
  const [isPermissionGranted, setIsPermissionGranted] = useState(false);
  
  useEffect(() => {
    oneSignalService.initialize(appId);
  }, [appId]);
  
  const requestPermission = async () => {
    const granted = await oneSignalService.requestPermission();
    setIsPermissionGranted(granted);
  };
  
  const setUserDetails = (email: string, phone: string) => {
    oneSignalService.setEmail(email);
    oneSignalService.setSmsNumber(phone);
  };
  
  return (
    <NotificationContext.Provider value={{ isPermissionGranted, requestPermission, setUserDetails }}>
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotifications = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within NotificationProvider');
  }
  return context;
};
```

### Custom Hook

```typescript
// src/hooks/useNotifications.ts
import { useEffect, useState, useCallback } from 'react';
import { OneSignal, LogLevel } from 'react-native-onesignal';

export const useOneSignal = (appId: string) => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [hasPermission, setHasPermission] = useState(false);
  
  useEffect(() => {
    OneSignal.Debug.setLogLevel(LogLevel.Verbose);
    OneSignal.initialize(appId);
    setIsInitialized(true);
    
    // Check current permission status
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

## Demo Welcome View (React Native)

When using the demo App ID, create this view:

### WelcomeScreen.tsx

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
const PHONE_REGEX = /^\+[1-9]\d{9,14}$/;

export const WelcomeScreen: React.FC = () => {
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [errors, setErrors] = useState<{ email?: string; phone?: string }>({});
  
  const isEmailValid = EMAIL_REGEX.test(email);
  const isPhoneValid = PHONE_REGEX.test(phone);
  const isFormValid = isEmailValid && isPhoneValid;
  
  const validateFields = () => {
    const newErrors: { email?: string; phone?: string } = {};
    
    if (email && !isEmailValid) {
      newErrors.email = 'Enter a valid email address';
    }
    if (phone && !isPhoneValid) {
      newErrors.phone = 'Use format: +1234567890';
    }
    
    setErrors(newErrors);
  };
  
  const handleSubmit = async () => {
    if (!isFormValid) return;
    
    setIsLoading(true);
    
    try {
      OneSignal.User.addEmail(email);
      OneSignal.User.addSms(phone);
      OneSignal.User.addTag('demo_user', 'true');
      OneSignal.User.addTag('welcome_sent', Date.now().toString());
      
      // Small delay to ensure data is sent
      await new Promise(resolve => setTimeout(resolve, 500));
      
      setShowSuccess(true);
    } catch (error) {
      console.error('Error submitting:', error);
    } finally {
      setIsLoading(false);
    }
  };
  
  if (showSuccess) {
    return (
      <View style={styles.container}>
        <View style={styles.successContainer}>
          <Text style={styles.checkmark}>✓</Text>
          <Text style={styles.successTitle}>Success!</Text>
          <Text style={styles.successMessage}>
            Check your email and phone for a welcome message!
          </Text>
        </View>
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
              style={[styles.input, errors.email ? styles.inputError : null]}
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
          
          <View style={styles.inputContainer}>
            <Text style={styles.label}>Phone Number</Text>
            <TextInput
              style={[styles.input, errors.phone ? styles.inputError : null]}
              value={phone}
              onChangeText={setPhone}
              onBlur={validateFields}
              placeholder="+1 555 123 4567"
              keyboardType="phone-pad"
            />
            {errors.phone && <Text style={styles.errorText}>{errors.phone}</Text>}
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

### TypeScript Version with React Native Paper

```typescript
import React, { useState } from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import {
  TextInput,
  Button,
  Text,
  Surface,
  HelperText,
  ActivityIndicator,
} from 'react-native-paper';
import { OneSignal } from 'react-native-onesignal';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_REGEX = /^\+[1-9]\d{9,14}$/;

export const WelcomeScreen: React.FC = () => {
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  
  const isEmailValid = EMAIL_REGEX.test(email);
  const isPhoneValid = PHONE_REGEX.test(phone);
  const isFormValid = isEmailValid && isPhoneValid;
  
  const handleSubmit = async () => {
    if (!isFormValid) return;
    
    setIsLoading(true);
    
    try {
      OneSignal.User.addEmail(email);
      OneSignal.User.addSms(phone);
      OneSignal.User.addTag('demo_user', 'true');
      OneSignal.User.addTag('welcome_sent', Date.now().toString());
      
      await new Promise(resolve => setTimeout(resolve, 500));
      setShowSuccess(true);
    } finally {
      setIsLoading(false);
    }
  };
  
  if (showSuccess) {
    return (
      <View style={styles.container}>
        <Surface style={styles.successSurface}>
          <Text variant="displaySmall" style={styles.checkmark}>✓</Text>
          <Text variant="headlineMedium">Success!</Text>
          <Text variant="bodyLarge" style={styles.successMessage}>
            Check your email and phone for a welcome message!
          </Text>
        </Surface>
      </View>
    );
  }
  
  return (
    <ScrollView contentContainerStyle={styles.scrollContent}>
      <Surface style={styles.surface}>
        <Text variant="headlineSmall" style={styles.title}>
          OneSignal Integration Complete!
        </Text>
        <Text variant="bodyMedium" style={styles.subtitle}>
          Enter your details to receive a welcome message
        </Text>
        
        <TextInput
          label="Email Address"
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          mode="outlined"
          style={styles.input}
          error={email.length > 0 && !isEmailValid}
        />
        <HelperText type="error" visible={email.length > 0 && !isEmailValid}>
          Enter a valid email address
        </HelperText>
        
        <TextInput
          label="Phone Number"
          value={phone}
          onChangeText={setPhone}
          keyboardType="phone-pad"
          mode="outlined"
          style={styles.input}
          error={phone.length > 0 && !isPhoneValid}
        />
        <HelperText type="error" visible={phone.length > 0 && !isPhoneValid}>
          Use format: +1234567890
        </HelperText>
        
        <Button
          mode="contained"
          onPress={handleSubmit}
          disabled={!isFormValid || isLoading}
          loading={isLoading}
          style={styles.button}
        >
          Send Welcome Message
        </Button>
      </Surface>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 16,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 16,
  },
  surface: {
    padding: 24,
    borderRadius: 12,
    elevation: 2,
  },
  successSurface: {
    padding: 32,
    borderRadius: 12,
    elevation: 2,
    alignItems: 'center',
  },
  title: {
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    textAlign: 'center',
    marginBottom: 24,
    color: '#666',
  },
  input: {
    marginBottom: 4,
  },
  button: {
    marginTop: 16,
  },
  checkmark: {
    color: '#27ae60',
    marginBottom: 16,
  },
  successMessage: {
    textAlign: 'center',
    marginTop: 8,
    color: '#666',
  },
});
```

---

## Testing

### Jest Unit Tests

```typescript
import { oneSignalService } from '../services/oneSignalService';
import { OneSignal } from 'react-native-onesignal';

jest.mock('react-native-onesignal', () => ({
  OneSignal: {
    initialize: jest.fn(),
    login: jest.fn(),
    logout: jest.fn(),
    User: {
      addEmail: jest.fn(),
      addSms: jest.fn(),
      addTag: jest.fn(),
    },
    Notifications: {
      requestPermission: jest.fn().mockResolvedValue(true),
    },
    Debug: {
      setLogLevel: jest.fn(),
    },
  },
}));

describe('OneSignalService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });
  
  it('initializes OneSignal with app ID', () => {
    oneSignalService.initialize('test-app-id');
    expect(OneSignal.initialize).toHaveBeenCalledWith('test-app-id');
  });
  
  it('sets email correctly', () => {
    oneSignalService.setEmail('test@example.com');
    expect(OneSignal.User.addEmail).toHaveBeenCalledWith('test@example.com');
  });
  
  it('requests permission and returns result', async () => {
    const result = await oneSignalService.requestPermission();
    expect(result).toBe(true);
  });
});
```

### Component Tests

```typescript
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { WelcomeScreen } from '../screens/WelcomeScreen';

jest.mock('react-native-onesignal');

describe('WelcomeScreen', () => {
  it('renders form initially', () => {
    const { getByText, getByPlaceholderText } = render(<WelcomeScreen />);
    
    expect(getByText('OneSignal Integration Complete!')).toBeTruthy();
    expect(getByPlaceholderText('you@example.com')).toBeTruthy();
    expect(getByPlaceholderText('+1 555 123 4567')).toBeTruthy();
  });
  
  it('disables submit button with invalid input', () => {
    const { getByText } = render(<WelcomeScreen />);
    const button = getByText('Send Welcome Message');
    
    // Button should be disabled initially
    expect(button.props.accessibilityState?.disabled).toBe(true);
  });
  
  it('enables submit button with valid input', () => {
    const { getByText, getByPlaceholderText } = render(<WelcomeScreen />);
    
    fireEvent.changeText(getByPlaceholderText('you@example.com'), 'test@example.com');
    fireEvent.changeText(getByPlaceholderText('+1 555 123 4567'), '+14155551234');
    
    const button = getByText('Send Welcome Message');
    expect(button.props.accessibilityState?.disabled).toBeFalsy();
  });
});
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| iOS build fails | Run `cd ios && pod install --repo-update` |
| Android build fails | Check `google-services.json` and sync gradle |
| Module not found | Clear Metro cache: `npx react-native start --reset-cache` |
| Notifications not received | Verify both iOS and Android platform configurations |
| Permission always false | Check notification settings in device Settings app |
| TypeScript errors | Ensure `@types/react-native-onesignal` is installed if needed |
