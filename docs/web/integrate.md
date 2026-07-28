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

- [ ] `OneSignalSDKWorker.js` placed at the location that maps to the site root (or a scoped subdirectory when an existing service worker requires it — see Step A)
- [ ] The worker file is included in the production build output and publicly reachable on the origin
- [ ] SDK initialized once, as early as possible, with the App ID
- [ ] All OneSignal access goes through a single point — the wrapper package directly, or the CDN service module (see Step C)
- [ ] Push permission requested **only** from the verification dialog's "Got it" button — never automatically on page load

---

## SDK Version Selection

The Web SDK is delivered two ways. Choose based on the detected framework. **The shared guidelines' *SDK Version Selection* (`releases.json`) step applies only to the npm-wrapper path below — skip it for CDN.**

### CDN (plain HTML, and the safe default for any site)

The CDN endpoint is **evergreen**: `v16` always serves the current stable Web SDK build. There is **no version to pin and no `releases.json` lookup to perform** for this path — just use the URL exactly as shown:

```
https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js
```

Do **not** fetch or embed a build number. (The Web entry's `channels.stable.version` in `releases.json` — e.g. `160607` — is the internal build the `v16` path currently serves; it must never appear in the URL.)

### npm wrapper (React / Vue / Angular)

When a first-party wrapper matches the framework, prefer it. **This is the only web path where the `releases.json` version step applies:** pin the wrapper's version from the official releases JSON (`https://onesignal.github.io/sdk-releases/releases.json`), using the **Stable** track unless the user asked for Current.

`releases.json` is a top-level JSON array of SDK entries; find the entry by `name` and read the exact version from `<entry>.channels.stable.version`:

| Framework | Package | releases.json entry (`name`) |
|-----------|---------|------------------------------|
| React / Next.js | `react-onesignal` | `React` |
| Vue 3 | `@onesignal/onesignal-vue3` | `Vue3` |
| Angular | `onesignal-ngx` | `Angular` |

For any framework without a first-party wrapper (Svelte, plain HTML, etc.), use the CDN approach.

---

## Step A — Service Worker File (Deterministic, Do Not Improvise)

Create a file named **exactly** `OneSignalSDKWorker.js` with **exactly** this content — do not generate, rename, or modify it:

```javascript
importScripts("https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.sw.js");
```

> This one line is the entire hostable worker file. It is intentionally tiny: it just imports the real, versioned worker from OneSignal's CDN. The OneSignal dashboard offers an identical file for download — use it to double-check the contents if needed, but the line above is authoritative for v16.

### Where the file goes — follow this procedure

The file must ultimately be reachable at the **root of the deployed origin** (`https://yourdomain.com/OneSignalSDKWorker.js`), unless an existing service worker forces a subdirectory (see A.3). Do **not** guess the location from the framework name alone — derive it from the project's own configuration by following A.1 → A.4 in order.

#### A.1 — Locate the app root

Find the `package.json` whose scripts actually build and serve the site (`dev` / `build` / `start`). In a monorepo (npm/yarn/pnpm workspaces, Nx, Turborepo), there may be several packages: the worker belongs inside the **target app's** package — never create a `public/` directory at the repository root of a monorepo. If more than one web app could plausibly be the target, ask the user which one to integrate.

#### A.2 — Determine the static-assets directory from config, not convention

Check for framework/bundler config files **before** concluding the project is plain HTML: `vite.config.*`, `next.config.*`, `angular.json`, `svelte.config.*`, `nuxt.config.*`, `astro.config.*`, `gatsby-config.*`, etc. Vite projects also keep `index.html` at the project root, so an `index.html` at the root does **not** by itself mean plain HTML.

Then read the config for a static-assets override — e.g. Vite `publicDir`, Angular `assets` entries, SvelteKit `kit.files.assets` — and use the configured directory when one is set. Only when there is no override, use the framework default:

| Framework | Default location (relative to app root) | Notes |
|-----------|------------------------------------------|-------|
| React (CRA or Vite) | `public/` | copied to root at build |
| Next.js | `public/` | served from root at runtime |
| Vue 3 (Vite) | `public/` | copied to root at build |
| Angular (modern layout: `angular.json` assets includes `"input": "public"`) | `public/` | copied to root at build |
| Angular (older layout: `src/`-based assets) | `src/` **and** add `"src/OneSignalSDKWorker.js"` as its own entry in `angular.json` → `projects.<app>.architect.build.options.assets` | a direct file entry is emitted at the output root — do **NOT** drop it into `src/assets/`, which emits to `/assets/`, not the root |
| SvelteKit | `static/` | served from root |
| Nuxt 3 | `public/` (Nuxt 2: `static/`) | served from root |
| Gatsby / Astro | `static/` / `public/` respectively | served from root |
| Plain HTML / vanilla JS (no bundler config found) | site root (next to `index.html`) | served directly |

#### A.3 — Check for existing service workers before placing the file

Search the project for an existing service worker: `navigator.serviceWorker.register(...)` calls, a `sw.js` / `service-worker.js` in the static dir, or PWA tooling (`next-pwa`, `vite-plugin-pwa`, `@angular/service-worker` / `ngsw-config.json`, Workbox).

* **No existing worker (the common case):** place `OneSignalSDKWorker.js` at the location from A.2 so it is served from the origin root. No extra `init` options are needed.
* **Existing worker at root scope (e.g. a PWA):** only one service worker can control a scope — do **not** overwrite it, merge into it, or add a second root-scope worker. Instead, place `OneSignalSDKWorker.js` in a dedicated subdirectory of the static dir (e.g. `push/onesignal/`) and pass both options in `init`:

  ```javascript
  serviceWorkerPath: "push/onesignal/OneSignalSDKWorker.js",
  serviceWorkerParam: { scope: "/push/onesignal/" },
  ```

  Flag this choice in the final summary. (Combining OneSignal into the existing worker file via `importScripts` is also documented, but prefer the separate-scope approach — see [OneSignal service worker](https://documentation.onesignal.com/docs/onesignal-service-worker).)

#### A.4 — Verify placement (mandatory — do not skip or delegate)

After placing the file, verify it **yourself**. Do not hand this off to the developer when the project has runnable scripts:

* **Frameworks that copy static assets at build time** (Vite, CRA, Angular, SvelteKit, Astro, Gatsby): run the production build and confirm `OneSignalSDKWorker.js` exists at the **web root of the build output** (e.g. `dist/`, `build/`, `dist/<app>/browser/`). If it is missing, the placement is wrong — fix the placement; do not work around it.
* **Frameworks that serve static files at runtime** (Next.js, Nuxt — `public/` is not copied into the build output): use a running dev server and confirm `curl -sI http://localhost:<port>/OneSignalSDKWorker.js` returns HTTP 200 with a JavaScript content-type (`application/javascript`, not `text/html`).
* Confirm exactly **one** copy of the file exists in the repo — remove any stray copies left at wrong locations by earlier attempts.

Only if the project has no build script and no way to run a dev server may verification be handed to the developer — and then the final summary must state that placement is **unverified** and give the exact URL to check.

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
npm install --save @onesignal/onesignal-vue3
```

```typescript
// main.ts
import { createApp } from 'vue';
import OneSignalVuePlugin from '@onesignal/onesignal-vue3';
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
import { OneSignal } from 'onesignal-ngx';

@Component({ selector: 'app-root', templateUrl: './app.component.html' })
export class AppComponent implements OnInit {
  constructor(private oneSignal: OneSignal) {}

  ngOnInit(): void {
    this.oneSignal.init({ appId: 'YOUR_ONESIGNAL_APP_ID' });
  }
}
```

Place `OneSignalSDKWorker.js` per Step A: modern Angular layouts drop it in `public/`; older `src/`-based layouts also need the `angular.json` assets entry.

---

## Step C — Centralized OneSignal Access (Required)

The shared guidelines require isolating OneSignal behind a single access point. How you satisfy that depends on the integration path.

### Wrapper projects (React / Vue / Angular)

The wrapper package **is** the centralized, typed interface — a singleton (`react-onesignal`), a plugin exposing `$OneSignal` / `useOneSignal()` (`@onesignal/onesignal-vue3`), or an injectable service (`onesignal-ngx`). Use it directly as shown in Step B, and keep usage consistent (the same singleton import, the same injected service). Because the wrappers ship their own types, wrapper-based code needs **no** `any` and no ambient declarations.

**Do NOT add a module that re-exports or re-wraps the wrapper.** That indirection is clunky, fights the wrapper's own typings, and isn't how these packages are used in practice. Route app-specific concerns (identity, consent) through your existing app layers by calling the wrapper from them — don't build a parallel SDK facade.

### CDN / global projects

The raw `window.OneSignalDeferred` global has no typed, single entry point, so here you *do* create a small centralized module. In strict TypeScript projects (especially with `@typescript-eslint/no-explicit-any`), add a minimal ambient declaration for the surface you use instead of casting to `any`; plain-JS projects can skip the `.d.ts`.

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
// CDN/global path only: resolve the SDK from the OneSignalDeferred queue,
// typed via src/types/onesignal.d.ts.
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

## Definition of Done & Verification Handoff

Web push cannot be fully verified from a coding agent: the parts that prove push actually works require a real browser, a secure origin (HTTPS or `localhost`), and dashboard state you cannot touch. Be honest about this boundary — report the integration as **code-complete and building**, not as "push works," and hand off the runtime checklist.

### What the agent can and should verify

- [ ] Project type-checks / builds without errors (`npm run build` or equivalent)
- [ ] `OneSignalSDKWorker.js` exists with the exact one-line contents and is emitted to the build output's web root (e.g. `public/` → `/`)
- [ ] If a dev server is running, the worker is reachable and served as JavaScript — e.g. `curl -sI http://localhost:<port>/OneSignalSDKWorker.js` shows `content-type: application/javascript` (not `text/html`)
- [ ] SDK is initialized exactly once, as early as possible, with the App ID
- [ ] All OneSignal access goes through a single point (wrapper package, or the CDN service module)
- [ ] Push permission is requested **only** from the verification dialog's "Got it" button

### What only the developer can verify (report as a handoff, do not claim done)

- [ ] Dashboard app configured as **Custom Code** with **Site URL** matching the exact origin (separate app for localhost)
- [ ] Loaded over HTTPS (or `localhost`) in a normal, non-incognito window
- [ ] SDK loads from the CDN at runtime and the permission prompt appears from "Got it"
- [ ] A real subscription appears under **Audience → Subscriptions** (status *Subscribed*) — this is the runtime equivalent of the non-null `PushSubscription.id`
- [ ] A test push (dashboard or API) is received on the device

State clearly in the final summary which items you verified and which are the developer's to complete.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SDK never initializes | Confirm the site is on HTTPS (or `localhost`), not incognito |
| "Site URL mismatch" / no prompt | Dashboard **Site URL** must exactly match the origin; localhost needs its own app |
| Service worker 404 | The `OneSignalSDKWorker.js` file isn't reachable at the configured path on the origin |
| Worker served as `text/html` | Ensure the host serves `.js` with `content-type: application/javascript` |
| Worker works locally but not in prod | Confirm the build copies the file to the deploy root (e.g. `public/` → `/`) |
| Existing PWA / service worker stops working, or OneSignal worker never activates | Only one service worker can control a scope — move the OneSignal worker to a scoped subdirectory with `serviceWorkerPath` + `serviceWorkerParam` (see Step A.3) |
| Permission prompt never appears | Permission is requested only from the "Got it" button; also check the browser isn't blocking notifications |
| iOS Safari not subscribing | iOS needs 16.4+, a `manifest.json`, and the user must add the site to their home screen — see the iOS web push docs |

---

## Constraints Recap (Web-Specific)

* Do NOT hardcode a demo/fallback App ID — use the one from the user's prompt.
* Do NOT request push permission on page load — only from the verification dialog.
* Do NOT host the service worker on a CDN or a different origin.
* Do NOT pin the CDN URL to a build number — use the `v16` path.
* Keep OneSignal access consistent — call the wrapper package directly (do NOT re-wrap it), or the CDN service module for the global path.
