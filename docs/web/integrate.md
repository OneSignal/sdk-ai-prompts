# Web Integration Guide

## Official Documentation

* [Web SDK setup](https://documentation.onesignal.com/docs/web-sdk-setup)
* [Web SDK reference](https://documentation.onesignal.com/docs/web-sdk-reference)
* [OneSignal service worker](https://documentation.onesignal.com/docs/onesignal-service-worker)
* [Website SDK repository](https://github.com/OneSignal/OneSignal-Website-SDK)
* Framework wrappers: [react-onesignal](https://github.com/OneSignal/react-onesignal), [onesignal-vue3](https://github.com/OneSignal/onesignal-vue3), [onesignal-ngx](https://github.com/OneSignal/onesignal-ngx)

---

## User Prompts

Before beginning the integration, detect the framework from the codebase, then confirm with the user and ask about language:

1. **Framework**: Inspect the project (e.g. `package.json` dependencies, config files) to detect the framework, then confirm it with the user. Supported targets:
   - Plain HTML / vanilla JS (no bundler)
   - React (Create React App or Vite)
   - Next.js
   - Vue 3
   - Angular
   - Svelte / SvelteKit
   - Other (fall back to the CDN snippet approach)

2. **Language Preference** (where a choice exists): JavaScript or TypeScript. Use the user's response to decide which code examples to apply.

> Do NOT ask which *platform* this is — it is already known to be Web. Only detect/confirm the **framework** and language.

---

## Critical Constraints (Read First)

Web push has hard browser requirements that differ from mobile. The integration will silently fail if these are not met:

1. **HTTPS only.** Web push does not work over HTTP, or in incognito/private windows. The **only** exception is `localhost` / `127.0.0.1`, which browsers treat as secure origins for development.
2. **Same-origin service worker.** The `OneSignalSDKWorker.js` file **must** be served from the site's own origin (e.g. `https://yourdomain.com/OneSignalSDKWorker.js`). It **cannot** be hosted on a CDN or a different origin, and cannot be reached via a redirect.
3. **Correct content-type.** The worker file must be served as JavaScript (`content-type: application/javascript`), never `text/html`.
4. **Dashboard app must be configured as "Custom Code."** In the OneSignal dashboard under **Settings → Push & In-App → Web**, the app must use the **Custom Code** (Typical Site) integration and the **Site URL** must exactly match the origin being tested (including `http://localhost` for local testing — use a *separate* OneSignal app for localhost).

These are environment/account prerequisites the agent cannot fully perform from the codebase. Call them out explicitly in the final summary so the developer can complete them in the dashboard.

---

## Pre-Flight Checklist

Before considering the integration complete, verify ALL of the following:

### OneSignal Dashboard (developer action)

- [ ] A OneSignal app exists with the **Web** platform configured as **Custom Code**
- [ ] **Site URL** matches the exact origin (production or localhost)
- [ ] For local testing: a **separate** OneSignal app whose Site URL matches the localhost URL, with "Treat HTTP localhost as HTTPS" enabled if serving over HTTP
- [ ] App ID obtained (provided in the user's prompt)

### Codebase

- [ ] `OneSignalSDKWorker.js` placed at the location that maps to the site root (or a configured subdirectory — see table below)
- [ ] The worker file is included in the production build output and publicly reachable on the origin
- [ ] SDK initialized once, as early as possible, with the App ID
- [ ] All OneSignal calls routed through a single centralized wrapper module
- [ ] Push permission requested **only** from the verification dialog's "Got it" button — never automatically on page load

---

## SDK Version Selection

The Web SDK is delivered two ways. Choose based on the detected framework:

### CDN (plain HTML, and the safe default for any site)

Load the SDK from the **evergreen v16 CDN endpoint** — there is no version pin to choose:

```
https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js
```

The `channels.stable.version` value for the **Web** entry in `https://onesignal.github.io/sdk-releases/releases.json` (e.g. an all-numeric build like `160607`) is the internal build number that the v16 CDN URL currently serves. **Do not** put that build number into the CDN URL — always use the `v16` path exactly as shown.

### npm wrapper (React / Vue / Angular)

When a first-party wrapper matches the framework, prefer it and pin the version from the official releases JSON (`https://onesignal.github.io/sdk-releases/releases.json`), using the **Stable** track unless the user asked for Current:

| Framework | Package | releases.json entry (`name`) |
|-----------|---------|------------------------------|
| React / Next.js | `react-onesignal` | `React` |
| Vue 3 | `onesignal-vue3` | `Vue3` |
| Angular | `onesignal-ngx` | `Angular` |

Read the exact version from `<entry>.channels.stable.version`. For any framework without a first-party wrapper (Svelte, plain HTML, etc.), use the CDN approach.

---

## Step A — Service Worker File (Deterministic, Do Not Improvise)

Create a file named **exactly** `OneSignalSDKWorker.js` with **exactly** this content — do not generate, rename, or modify it:

```javascript
importScripts("https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.sw.js");
```

> This one line is the entire hostable worker file. It is intentionally tiny: it just imports the real, versioned worker from OneSignal's CDN. The OneSignal dashboard offers an identical file for download — use it to double-check the contents if needed, but the line above is authoritative for v16.

### Where the file goes (by framework)

The file must ultimately be reachable at the **root of the deployed origin** (`https://yourdomain.com/OneSignalSDKWorker.js`) unless you configure a subdirectory in the dashboard. Place the source file where the framework copies static assets to the web root:

| Framework | Location in repo | Notes |
|-----------|------------------|-------|
| Plain HTML / vanilla JS | site root (next to `index.html`) | served directly |
| React (CRA or Vite) | `public/` | copied to root at build |
| Next.js | `public/` | served from root |
| Vue 3 (Vite) | `public/` | served from root |
| Angular | `src/` **and** add it to `angular.json` → `projects.<app>.architect.build.options.assets` | ensures it is emitted to the output root |
| SvelteKit | `static/` | served from root |
| Nuxt 3 | `public/` (Nuxt 2: `static/`) | served from root |
| Gatsby / Astro | `static/` / `public/` respectively | served from root |

If you must place the worker in a subdirectory, the dashboard's **Advanced settings → Service workers → Path to service worker files** and **scope** must match, and the SDK `init` must be given `serviceWorkerParam` / `serviceWorkerPath`. Prefer the root unless the project structure forces otherwise; flag any subdirectory choice in the summary.

### Verify

After placing the file, confirm (or instruct the developer to confirm) that visiting `/{path}/OneSignalSDKWorker.js` on the running site returns the JavaScript above with a JavaScript content-type.

---

## Step B — SDK Initialization

Initialize OneSignal exactly once, as early as possible. Use the approach that matches the detected framework.

### CDN snippet (plain HTML / any site without a first-party wrapper)

Add to the `<head>` of the site's main HTML template:

```html
<script src="https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js" defer></script>
<script>
  window.OneSignalDeferred = window.OneSignalDeferred || [];
  OneSignalDeferred.push(async function (OneSignal) {
    await OneSignal.init({
      appId: "YOUR_ONESIGNAL_APP_ID",
      // Only include the next line when running on localhost:
      // allowLocalhostAsSecureOrigin: true,
    });
  });
</script>
```

> Add `allowLocalhostAsSecureOrigin: true` to the `init` options **only** for local development. Remove it (or gate it behind an environment check) for production.

### React (Create React App or Vite)

```bash
npm install --save react-onesignal
```

Initialize once at app startup (guard against React 18 StrictMode double-invocation):

```typescript
// src/onesignal.ts
import OneSignal from 'react-onesignal';

let initialized = false;

export async function initOneSignal(appId: string): Promise<void> {
  if (initialized) return;
  initialized = true;
  await OneSignal.init({
    appId,
    // allowLocalhostAsSecureOrigin: true, // localhost only
  });
}
```

```typescript
// src/App.tsx
import { useEffect } from 'react';
import { initOneSignal } from './onesignal';

const ONESIGNAL_APP_ID = 'YOUR_ONESIGNAL_APP_ID';

export default function App() {
  useEffect(() => {
    void initOneSignal(ONESIGNAL_APP_ID);
  }, []);

  return <YourAppContent />;
}
```

### Next.js

Use `react-onesignal` from a **client** component (initialization must run in the browser). Place `OneSignalSDKWorker.js` in `public/`.

```typescript
'use client';

import { useEffect } from 'react';
import OneSignal from 'react-onesignal';

const ONESIGNAL_APP_ID = 'YOUR_ONESIGNAL_APP_ID';

export function OneSignalProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    OneSignal.init({ appId: ONESIGNAL_APP_ID }).catch(console.error);
  }, []);

  return <>{children}</>;
}
```

Render `<OneSignalProvider>` in your root layout. In the Pages Router, initialize inside `useEffect` in `_app.tsx` instead.

### Vue 3

```bash
npm install --save onesignal-vue3
```

```typescript
// main.ts
import { createApp } from 'vue';
import OneSignalVuePlugin from 'onesignal-vue3';
import App from './App.vue';

createApp(App)
  .use(OneSignalVuePlugin, {
    appId: 'YOUR_ONESIGNAL_APP_ID',
  })
  .mount('#app');
```

### Angular

```bash
npm install --save onesignal-ngx
```

```typescript
// app.component.ts
import { Component, OnInit } from '@angular/core';
import OneSignal from 'onesignal-ngx';

@Component({ selector: 'app-root', templateUrl: './app.component.html' })
export class AppComponent implements OnInit {
  constructor(private oneSignal: OneSignal) {}

  ngOnInit(): void {
    this.oneSignal.init({ appId: 'YOUR_ONESIGNAL_APP_ID' });
  }
}
```

Remember to add `OneSignalSDKWorker.js` to the `assets` array in `angular.json`.

---

## Step C — Centralized OneSignal Wrapper (Required)

Per the shared guidelines, isolate all OneSignal calls behind a single module. For the CDN approach, wrap access to the deferred global; for the npm wrappers, import the SDK inside this module only.

> **TypeScript projects:** The npm wrappers (`react-onesignal`, `onesignal-vue3`, `onesignal-ngx`) ship their own types, so wrapper-based code needs **no** `any` — import the typed `OneSignal` and use it directly. Only the **CDN/global** path (`window.OneSignalDeferred`) is untyped. In strict projects — especially those running `@typescript-eslint/no-explicit-any` — add a small ambient declaration for the surface you use instead of casting to `any`; plain-JS projects can skip it.

```typescript
// src/types/onesignal.d.ts
// Minimal typings for the CDN/global (window.OneSignalDeferred) path only.
// Not needed when using a typed npm wrapper.

export interface OneSignalPushSubscription {
  readonly id: string | null | undefined;
  readonly token: string | null | undefined;
  readonly optedIn: boolean;
  addEventListener(event: 'change', listener: (change?: unknown) => void): void;
  removeEventListener(event: 'change', listener: (change?: unknown) => void): void;
}

export interface OneSignalUser {
  addEmail(email: string): void;
  addSms(sms: string): void;
  addTag(key: string, value: string): void;
  readonly PushSubscription: OneSignalPushSubscription;
}

export interface OneSignalApi {
  init(options: { appId: string; allowLocalhostAsSecureOrigin?: boolean }): Promise<void>;
  login(externalId: string): Promise<void>;
  logout(): Promise<void>;
  Notifications: { requestPermission(): Promise<void> };
  User: OneSignalUser;
}

declare global {
  interface Window {
    OneSignalDeferred: Array<(oneSignal: OneSignalApi) => void>;
  }
}

export {};
```

```typescript
// src/services/oneSignalService.ts
//
// The npm-wrapper version imports OneSignal directly (fully typed):
//   import OneSignal from 'react-onesignal';
// The CDN version resolves the SDK from the OneSignalDeferred queue,
// typed via src/types/onesignal.d.ts:
import type { OneSignalApi } from '../types/onesignal';

function withOneSignal(fn: (oneSignal: OneSignalApi) => void): void {
  window.OneSignalDeferred = window.OneSignalDeferred || [];
  window.OneSignalDeferred.push(fn);
}

export const OneSignalService = {
  login(externalId: string): void {
    withOneSignal((os) => os.login(externalId));
  },
  logout(): void {
    withOneSignal((os) => os.logout());
  },
  addEmail(email: string): void {
    withOneSignal((os) => os.User.addEmail(email));
  },
  addSms(phone: string): void {
    withOneSignal((os) => os.User.addSms(phone));
  },
  addTag(key: string, value: string): void {
    withOneSignal((os) => os.User.addTag(key, value));
  },
  requestPermission(): void {
    withOneSignal((os) => os.Notifications.requestPermission());
  },
};
```

Keep the shape consistent with the codebase's existing service/module conventions.

---

## Push Subscription Verification Dialog (Web Adaptation)

The shared guidelines require a one-time "integration complete" confirmation that requests push permission on tap. Web differs from mobile in an important way:

> **On web, a push subscription ID is normally only assigned *after* the user grants permission.** So we cannot wait for a real subscription ID before requesting permission — that would be circular. Instead, on web the dialog is shown once **OneSignal has initialized**, its "Got it" button drives the permission request, and a push subscription observer then **confirms** registration by reading `OneSignal.User.PushSubscription.id` once the user opts in.

> **Detecting registration on web:** The public `OneSignal.User.PushSubscription.id` getter returns `undefined` while the ID is still the SDK's internal `local-` placeholder, and only exposes a real, server-assigned UUID once the device is registered. On web you therefore never check for the `local-` prefix yourself — **a non-null `id` means registered.** (The getter filters local IDs in the Website SDK's `PushSubscriptionNamespace`/`IDManager`.)

Show an **in-page modal** (not a mobile-style native alert — web has none). Build a minimal accessible modal with your framework, or fall back to `window.confirm` only if the project has no UI layer.

```typescript
let dialogShown = false;

function showIntegrationCompleteModal(onAcknowledge: () => void): void {
  // Replace with a framework-native modal. Minimal fallback:
  const ok = window.confirm(
    'Your OneSignal SDK integration is complete!\n\n' +
      'You can now send Push Notifications & In-App Messages through OneSignal. ' +
      'Press OK to enable push notifications.'
  );
  if (ok) onAcknowledge();
}

export function setupVerificationDialog(): void {
  // `OneSignal` is typed as OneSignalApi via src/types/onesignal.d.ts — no `any`.
  window.OneSignalDeferred = window.OneSignalDeferred || [];
  window.OneSignalDeferred.push((OneSignal) => {
    // The SDK is initialized here — show the one-time confirmation.
    if (!dialogShown) {
      dialogShown = true;
      showIntegrationCompleteModal(() => {
        OneSignal.Notifications.requestPermission();
      });
    }

    // Confirm registration once the user opts in. `id` is undefined until a real,
    // server-assigned ID exists — the SDK never exposes the internal `local-`
    // placeholder — so a non-null check is sufficient.
    OneSignal.User.PushSubscription.addEventListener('change', () => {
      const id = OneSignal.User.PushSubscription.id;
      if (id) {
        console.log('OneSignal push subscription registered:', id);
      }
    });
  });
}
```

Wire `setupVerificationDialog()` in right after initialization. Keep the title, message, and single **"Got it"** button text from the shared guidelines when building a real modal.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SDK never initializes | Confirm the site is on HTTPS (or `localhost`), not incognito |
| "Site URL mismatch" / no prompt | Dashboard **Site URL** must exactly match the origin; localhost needs its own app |
| Service worker 404 | The `OneSignalSDKWorker.js` file isn't reachable at the configured path on the origin |
| Worker served as `text/html` | Ensure the host serves `.js` with `content-type: application/javascript` |
| Worker works locally but not in prod | Confirm the build copies the file to the deploy root (e.g. `public/` → `/`) |
| Permission prompt never appears | Permission is requested only from the "Got it" button; also check the browser isn't blocking notifications |
| iOS Safari not subscribing | iOS needs 16.4+, a `manifest.json`, and the user must add the site to their home screen — see the iOS web push docs |

---

## Constraints Recap (Web-Specific)

* Do NOT hardcode a demo/fallback App ID — use the one from the user's prompt.
* Do NOT request push permission on page load — only from the verification dialog.
* Do NOT host the service worker on a CDN or a different origin.
* Do NOT pin the CDN URL to a build number — use the `v16` path.
* Keep all OneSignal calls inside the centralized wrapper module.
