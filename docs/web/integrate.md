# Web Integration Guide

## Official Documentation

* [Web SDK setup](https://documentation.onesignal.com/docs/en/web-sdk-setup)
* Framework guides: [React / Next.js](https://documentation.onesignal.com/docs/en/react-js-setup), [Vue](https://documentation.onesignal.com/docs/en/vue-js-setup), [Angular](https://documentation.onesignal.com/docs/en/angular-setup)
* [Web permission prompts](https://documentation.onesignal.com/docs/en/permission-requests)
* [OneSignal service worker](https://documentation.onesignal.com/docs/en/onesignal-service-worker)
* [Web SDK reference](https://documentation.onesignal.com/docs/en/web-sdk-reference)
* Framework wrappers: [react-onesignal](https://github.com/OneSignal/react-onesignal), [onesignal-vue3](https://github.com/OneSignal/onesignal-vue3), [onesignal-ngx](https://github.com/OneSignal/onesignal-ngx)

If this file and the official [Web SDK setup](https://documentation.onesignal.com/docs/en/web-sdk-setup) page disagree, follow the official page.

---

## User Prompts

Before beginning the integration, detect the framework from the codebase, then confirm it with the user together with the Step 1 questions (one round):

1. **Framework**: Inspect the project (e.g. `package.json` dependencies, config files) to detect the framework, then confirm it. Supported targets:
   - Plain HTML / vanilla JS (no bundler)
   - React (Create React App or Vite)
   - Next.js
   - Vue 3
   - Angular
   - Svelte / SvelteKit
   - Other (fall back to the CDN snippet approach)

2. **Language Preference** (where a choice exists): JavaScript or TypeScript. If the project already uses TypeScript, don't ask.

> Do NOT ask which *platform* this is — it is already known to be Web. Don't ask about google-services.json (web doesn't use it).

---

## Critical Constraints (Read First)

Web push has hard browser requirements that differ from mobile. The integration will silently fail if these are not met:

1. **HTTPS only.** Web push does not work over HTTP, or in incognito/private windows. The **only** exception is `localhost` / `127.0.0.1`, which browsers treat as secure origins for development.
2. **Same-origin service worker.** `OneSignalSDKWorker.js` **must** be served from the site's own origin. It **cannot** be hosted on a CDN or a different origin, and cannot be reached via a redirect.
3. **Correct content-type.** The worker file must be served as JavaScript (`content-type: application/javascript`), never `text/html`.
4. **Dashboard setup (developer action).** In **Settings → Push & In-App → Web**, the official guide recommends the **Typical Site** integration type. The **Site URL** must exactly match the origin being tested. For localhost, use a *separate* OneSignal app whose Site URL matches the localhost URL.

These are environment/account prerequisites the agent cannot perform from the codebase. Call them out in the final summary.

---

## Pre-Flight Checklist

### OneSignal Dashboard (developer action — list in the summary)

- [ ] A OneSignal app with the **Web** platform, integration type **Typical Site** (recommended)
- [ ] **Site URL** matches the exact origin (production or localhost)
- [ ] For local testing: a **separate** OneSignal app whose Site URL matches the localhost URL, with **Treat HTTP localhost as HTTPS** enabled if serving over HTTP
- [ ] **Permission prompts** configured under the web settings. With Typical Site, the dashboard controls when and how the prompt appears. Guide: https://documentation.onesignal.com/docs/en/permission-requests

### Codebase

- [ ] `OneSignalSDKWorker.js` placed so it is served from the site root (see Step A)
- [ ] The worker file is included in the production build output and publicly reachable on the origin
- [ ] SDK initialized once, as early as possible, with the App ID
- [ ] **No permission request in code.** Typical Site prompts come from the dashboard configuration (see **Push Permission Request**)

---

## SDK Version Selection

The Web SDK is delivered two ways. Choose based on the detected framework. **The shared guidelines' *SDK Version Selection* (`releases.json`) step applies only to the npm-wrapper path below — skip it for CDN.**

### CDN (plain HTML, and the safe default for any site)

The CDN endpoint is **evergreen**: `v16` always serves the current Web SDK build. There is **no version to pin**:

```
https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js
```

Do **not** put a build number in the URL. (The Web entry's `channels.current.version` in `releases.json`, e.g. `160700`, is the internal build number; it must never appear in the URL.)

### npm wrapper (React / Vue / Angular)

The official setup guide says to use the matching framework guide for Angular, React, or Vue sites. Install the wrapper at its **Current** version from `releases.json` (find the entry by `name`, read `<entry>.channels.current.version`):

| Framework | Package | releases.json entry (`name`) |
|-----------|---------|------------------------------|
| React / Next.js | `react-onesignal` | `React` |
| Vue 3 | `@onesignal/onesignal-vue3` | `Vue3` |
| Angular | `onesignal-ngx` | `Angular` |

For any framework without a first-party wrapper (Svelte, plain HTML, etc.), use the CDN approach.

---

## Step A — Service Worker File (Deterministic, Do Not Improvise)

Create a file named **exactly** `OneSignalSDKWorker.js` with **exactly** this content (from the official guide):

```javascript
importScripts("https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.sw.js");
```

### Where the file goes — follow this procedure

The file must be reachable at the **root of the deployed origin** (`https://yourdomain.com/OneSignalSDKWorker.js`), unless an existing service worker forces a subdirectory (see A.3). Derive the location from the project's configuration by following A.1 → A.4 in order.

#### A.1 — Locate the app root

Find the `package.json` whose scripts actually build and serve the site (`dev` / `build` / `start`). In a monorepo (npm/yarn/pnpm workspaces, Nx, Turborepo), the worker belongs inside the **target app's** package — never create a `public/` directory at the repository root of a monorepo. If more than one web app could plausibly be the target, ask the user which one to integrate.

#### A.2 — Determine the static-assets directory from config, not convention

Check for framework/bundler config files **before** concluding the project is plain HTML: `vite.config.*`, `next.config.*`, `angular.json`, `svelte.config.*`, `nuxt.config.*`, `astro.config.*`, `gatsby-config.*`, etc. Vite projects also keep `index.html` at the project root, so an `index.html` at the root does **not** by itself mean plain HTML.

Then read the config for a static-assets override — e.g. Vite `publicDir`, Angular `assets` entries, SvelteKit `kit.files.assets` — and use the configured directory when one is set. Only when there is no override, use the framework default:

| Framework | Default location (relative to app root) | Notes |
|-----------|------------------------------------------|-------|
| React (CRA or Vite) | `public/` | copied to root at build |
| Next.js | `public/` | served from root at runtime |
| Vue 3 (Vite) | `public/` | copied to root at build |
| Angular (modern layout: `angular.json` assets includes `"input": "public"`) | `public/` | copied to root at build |
| Angular (older layout: `src/`-based assets) | `src/` **and** add `"src/OneSignalSDKWorker.js"` as its own entry in `angular.json` → `projects.<app>.architect.build.options.assets` | a direct file entry is emitted at the output root — do **NOT** drop it into `src/assets/`, which emits to `/assets/` |
| SvelteKit | `static/` | served from root |
| Nuxt 3 | `public/` (Nuxt 2: `static/`) | served from root |
| Gatsby / Astro | `static/` / `public/` respectively | served from root |
| Plain HTML / vanilla JS (no bundler config found) | site root (next to `index.html`) | served directly |

#### A.3 — Check for existing service workers before placing the file

Search the project for an existing service worker: `navigator.serviceWorker.register(...)` calls, a `sw.js` / `service-worker.js` in the static dir, or PWA tooling (`next-pwa`, `vite-plugin-pwa`, `@angular/service-worker` / `ngsw-config.json`, Workbox).

* **No existing worker (the common case):** place `OneSignalSDKWorker.js` at the location from A.2 so it is served from the origin root. No extra settings are needed.
* **Existing worker at root scope (e.g. a PWA):** don't overwrite or merge into it. Place `OneSignalSDKWorker.js` in a subdirectory of the static dir (e.g. `push/onesignal/`). With Typical Site, the official guide sets the path **in the dashboard, not in code**: tell the developer to open **Settings → Push & In-App → Web → Advanced Push Settings**, enable **Customize service worker paths and filenames**, and set the path and registration scope to `/push/onesignal/` and the filename to `OneSignalSDKWorker.js`. Don't set `serviceWorkerPath` in code. Flag this in the summary.

#### A.4 — Verify placement (mandatory — do not skip or delegate)

After placing the file, verify it **yourself** when the project has runnable scripts:

* **Frameworks that copy static assets at build time** (Vite, CRA, Angular, SvelteKit, Astro, Gatsby): run the production build and confirm `OneSignalSDKWorker.js` exists at the **web root of the build output** (e.g. `dist/`, `build/`, `dist/<app>/browser/`). If it is missing, fix the placement.
* **Frameworks that serve static files at runtime** (Next.js, Nuxt): run a dev server and confirm `curl -sI http://localhost:<port>/OneSignalSDKWorker.js` returns HTTP 200 with a JavaScript content-type.
* **Plain HTML:** serve the folder (for example `npx serve .` or `python3 -m http.server`) and run the same `curl -sI` check.
* Confirm exactly **one** copy of the file exists in the repo.

Only if there is no way to serve the site may verification be handed to the developer — and then the summary must say placement is **unverified** and give the exact URL to check.

---

## Step B — SDK Initialization

Initialize OneSignal exactly once, as early as possible. Initialization only: no login, email, SMS, tag, or permission calls (see **Scope: initialization only** in the shared guidelines). Replace `YOUR_APP_ID` with the App ID from Step 1.

For local development on `localhost`, add `allowLocalhostAsSecureOrigin: true` to the `init` options, as the official guide says. Gate it behind an environment check (or tell the developer to remove it) for production.

### CDN snippet (plain HTML / any site without a first-party wrapper)

The official guide's snippet. Add it to the `<head>` of the site's main HTML template:

```html
<script src="https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js" defer></script>
<script>
  window.OneSignalDeferred = window.OneSignalDeferred || [];
  OneSignalDeferred.push(async function(OneSignal) {
    await OneSignal.init({
      appId: "YOUR_APP_ID",
      // allowLocalhostAsSecureOrigin: true, // localhost only
    });
  });
</script>
```

This snippet is the single place the site touches OneSignal; don't add a separate service module for initialization alone.

### React (Create React App or Vite)

```bash
npm install --save react-onesignal@X.Y.Z
```

Initialize once at app startup. Guard against React StrictMode running effects twice in development; don't remove StrictMode.

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

export default function App() {
  useEffect(() => {
    void initOneSignal('YOUR_APP_ID');
  }, []);

  // ...existing app content
}
```

### Next.js

Use `react-onesignal` from a **client** component (initialization must run in the browser). Place `OneSignalSDKWorker.js` in `public/`.

```typescript
'use client';

import { useEffect } from 'react';
import { initOneSignal } from '@/lib/onesignal'; // same module as the React example

export function OneSignalProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    initOneSignal('YOUR_APP_ID').catch(console.error);
  }, []);

  return <>{children}</>;
}
```

Render `<OneSignalProvider>` in your root layout. In the Pages Router, initialize inside `useEffect` in `_app.tsx` instead.

### Vue 3

```bash
npm install --save @onesignal/onesignal-vue3@X.Y.Z
```

```typescript
// main.ts
import { createApp } from 'vue';
import OneSignalVuePlugin from '@onesignal/onesignal-vue3';
import App from './App.vue';

createApp(App)
  .use(OneSignalVuePlugin, {
    appId: 'YOUR_APP_ID',
  })
  .mount('#app');
```

### Angular

```bash
npm install --save onesignal-ngx@X.Y.Z
```

```typescript
// app.component.ts
import { Component, OnInit } from '@angular/core';
import { OneSignal } from 'onesignal-ngx';

@Component({ selector: 'app-root', templateUrl: './app.component.html' })
export class AppComponent implements OnInit {
  constructor(private oneSignal: OneSignal) {}

  ngOnInit(): void {
    this.oneSignal.init({ appId: 'YOUR_APP_ID' });
  }
}
```

Place `OneSignalSDKWorker.js` per Step A: modern Angular layouts drop it in `public/`; older `src/`-based layouts also need the `angular.json` assets entry.

### Centralized access

The wrapper package **is** the centralized, typed interface: a singleton (`react-onesignal`), a plugin (`@onesignal/onesignal-vue3`), or an injectable service (`onesignal-ngx`). Use it directly as shown, from one place. **Don't add a module that re-exports or re-wraps the wrapper.**

---

## Push Permission Request

Don't request push permission in code. Following the official guide, the developer configures permission prompts in the OneSignal dashboard (Typical Site), and the SDK shows them after `init`. Don't add a verification dialog, a custom modal, or `Notifications.requestPermission()`.

In the Changes Summary, tell the developer to set up a prompt (for example the Slidedown) under the web settings: https://documentation.onesignal.com/docs/en/permission-requests. Without one, no prompt appears.

If the developer skipped the App ID, include this alert at the top of the Changes Summary, next to the App ID reminder:

> **OneSignal won't initialize on your site until you set your App ID.** With the placeholder, `OneSignal.init` fails, no permission prompt appears, and no subscriptions are created.

---

## Definition of Done & Verification Handoff

Web push cannot be fully verified from a coding agent: proving push works needs a real browser, a secure origin, and dashboard state you cannot touch. Report the integration as **code-complete and building**, not as "push works," and hand off the runtime checklist.

### What the agent can and should verify

- [ ] Project type-checks / builds without errors (`npm run build` or equivalent)
- [ ] `OneSignalSDKWorker.js` exists with the exact one-line contents and is emitted to the build output's web root
- [ ] If the site can be served, the worker is reachable and served as JavaScript (`curl -sI .../OneSignalSDKWorker.js` → 200, `application/javascript`)
- [ ] SDK is initialized exactly once, as early as possible, with the App ID
- [ ] No permission request, login, email, SMS, or tag calls in code

### What only the developer can verify (official guide's test steps)

1. Dashboard: Typical Site, **Site URL** matching the exact origin (separate app for localhost), and a permission prompt configured.
2. Open the site in Chrome, Firefox, Edge, or Safari over HTTPS (or `localhost`). Not Incognito or private browsing.
3. The prompt appears based on the permission prompt configuration. Click **Allow** on the native prompt.
4. In **Audience → Users & subscriptions → Subscriptions**, a new entry shows **Subscribed**.
5. Send a test push.

State clearly in the final summary which items you verified and which are the developer's to complete.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SDK never initializes | Confirm the site is on HTTPS (or `localhost` with `allowLocalhostAsSecureOrigin: true`), not incognito, and the App ID is set |
| "Site URL mismatch" / no prompt | Dashboard **Site URL** must exactly match the origin; localhost needs its own app |
| Prompt never appears | Configure a permission prompt in the dashboard; check the browser isn't blocking notifications for the site |
| Service worker 404 | `OneSignalSDKWorker.js` isn't reachable at the root (or at the dashboard's custom path) |
| Worker served as `text/html` | Ensure the host serves `.js` with `content-type: application/javascript` |
| Worker works locally but not in prod | Confirm the build copies the file to the deploy root (e.g. `public/` → `/`) |
| Existing PWA / service worker stops working | Only one service worker can control a scope — move the OneSignal worker to a subdirectory and set the path in the dashboard (Step A.3) |
| SDK initializes twice in React dev | StrictMode runs effects twice; keep the `initialized` guard |
| iOS Safari not subscribing | iOS needs 16.4+, a `manifest.json`, and the user must add the site to their home screen — see the iOS web push docs |

---

## Constraints Recap (Web-Specific)

* Do NOT hardcode a demo/fallback App ID — use the one from Step 1, or the `YOUR_APP_ID` placeholder if skipped.
* Do NOT request push permission in code — prompts come from the dashboard.
* Do NOT host the service worker on a CDN or a different origin.
* Do NOT pin the CDN URL to a build number — use the `v16` path.
* Keep OneSignal access in one place — the wrapper package directly (do NOT re-wrap it), or the CDN snippet.
