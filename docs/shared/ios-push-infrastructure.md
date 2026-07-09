# Shared iOS Push Infrastructure (Required for iOS Targets)

This section applies to integrations that produce an iOS app target, including native iOS, Flutter, Unity, and bare React Native. Some SDKs automate part or all of this setup (for example, the Unity SDK's iOS build post-processor); the platform-specific section of this prompt says whether to create these pieces manually or only verify them — follow it. Expo managed projects are configured through `onesignal-expo-plugin`; see the Expo prompt for the plugin-managed flow.

Confirmed Delivery tracking, rich notifications (images and action buttons), and correct badge counts all run inside a **Notification Service Extension (NSE)** that shares an **App Group** with the main app. **Without the NSE and App Group these features silently fail** — plain pushes may still arrive, so the omission is easy to miss. This setup is part of the minimal integration. Do NOT skip it.

Use the official iOS setup documentation as the source of truth:

* [OneSignal iOS SDK Setup](https://documentation.onesignal.com/docs/en/ios-sdk-setup)
* [OneSignal iOS SDK Repository](https://github.com/OneSignal/OneSignal-iOS-SDK)

## Required Outcomes

- [ ] `OneSignalNotificationServiceExtension` target exists and builds
- [ ] NSE target links the `OneSignalExtension` library (SPM) or the OneSignal iOS pod (CocoaPods)
- [ ] App Group `group.{MAIN_APP_BUNDLE_ID}.onesignal` is present in the entitlements of BOTH the main app target and the NSE target
- [ ] NSE deployment target matches the main app target
- [ ] `NotificationService` forwards to `OneSignalExtension.didReceiveNotificationExtensionRequest`
- [ ] Main app embeds the NSE `.appex` in an `Embed Foundation Extensions` build phase

## App Group Rules

The App Group format is:

```text
group.{MAIN_APP_BUNDLE_ID}.onesignal
```

Use the **main app target's** bundle identifier, NOT the NSE's.

* Correct: `group.com.example.myapp.onesignal`
* Wrong: `group.com.example.myapp.OneSignalNotificationServiceExtension.onesignal`

Both targets MUST use the exact same App Group string. If they differ, Confirmed Delivery, badges, and images silently fail.

Only if the app must reuse an **existing** App Group with a different name: add `OneSignal_app_groups_key` to the `Info.plist` of BOTH the main app target and the NSE target:

```xml
<key>OneSignal_app_groups_key</key>
<string>group.your-existing-group-id</string>
```

With automatic code signing, Xcode registers the App Group with the Apple Developer account on the next device build. A physical device build still needs a valid Apple Developer Team.

## Main App Entitlements

Add Push Notifications and the shared App Group to the main app target's `.entitlements` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.MAIN_APP_BUNDLE_ID.onesignal</string>
	</array>
</dict>
</plist>
```

Use `development` for development builds. Release/TestFlight/App Store builds generally use `production`, depending on the project's signing setup.

Wire the file into the main app target:

* Set `CODE_SIGN_ENTITLEMENTS = PATH/TO/App/App.entitlements;` in the main app target's Debug and Release build configurations (skip if already set — then just edit the existing file)
* For Xcode 16+ synchronized-group projects, add the entitlements file to the app group's `PBXFileSystemSynchronizedBuildFileExceptionSet` `membershipExceptions` (alongside `Info.plist`) so it is not copied into the bundle as a resource

## Background Modes

Enable Background Modes with Remote notifications for the main app target. When editing files directly, add or update the app `Info.plist` with:

```xml
<key>UIBackgroundModes</key>
<array>
	<string>remote-notification</string>
</array>
```

Also ensure the app target's Debug and Release build settings include:

```text
INFOPLIST_FILE = "PATH/TO/App/Info.plist";
INFOPLIST_KEY_UIBackgroundModes = "remote-notification";
```

If the project uses Xcode 16+ `PBXFileSystemSynchronizedRootGroup`, exclude `Info.plist` from the resource copy phase with a `PBXFileSystemSynchronizedBuildFileExceptionSet`. Otherwise Xcode may fail with "Multiple commands produce Info.plist".

## Create the Notification Service Extension Files

Create `OneSignalNotificationServiceExtension/` next to the `.xcodeproj` (or inside the generated iOS project root for cross-platform apps).

### Swift: `NotificationService.swift`

Use Swift unless the iOS project is clearly Objective-C-only.

```swift
import UserNotifications
import OneSignalExtension

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            // OneSignal downloads and attaches images, reports Confirmed Delivery,
            // and handles action buttons.
            OneSignalExtension.didReceiveNotificationExtensionRequest(
                self.receivedRequest,
                with: bestAttemptContent,
                withContentHandler: self.contentHandler
            )
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(
                self.receivedRequest,
                with: self.bestAttemptContent
            )
            contentHandler(bestAttemptContent)
        }
    }
}
```

### Objective-C: `NotificationService.h`

```objc
#import <UserNotifications/UserNotifications.h>

@interface NotificationService : UNNotificationServiceExtension
@end
```

### Objective-C: `NotificationService.m`

```objc
#import <OneSignalExtension/OneSignalExtension.h>
#import "NotificationService.h"

@interface NotificationService ()
@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNNotificationRequest *receivedRequest;
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                   withContentHandler:(void (^)(UNNotificationContent *_Nonnull))contentHandler {
    self.receivedRequest = request;
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];

    [OneSignalExtension didReceiveNotificationExtensionRequest:self.receivedRequest
                                withMutableNotificationContent:self.bestAttemptContent
                                            withContentHandler:self.contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
    [OneSignalExtension serviceExtensionTimeWillExpireRequest:self.receivedRequest
                               withMutableNotificationContent:self.bestAttemptContent];
    self.contentHandler(self.bestAttemptContent);
}

@end
```

### NSE `Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>OneSignalNotificationServiceExtension</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.usernotifications.service</string>
		<key>NSExtensionPrincipalClass</key>
		<string>$(PRODUCT_MODULE_NAME).NotificationService</string>
	</dict>
</dict>
</plist>
```

For Objective-C projects, set `NSExtensionPrincipalClass` to `NotificationService` (no `$(PRODUCT_MODULE_NAME).` prefix).

### NSE Entitlements

Create `OneSignalNotificationServiceExtension/OneSignalNotificationServiceExtension.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.MAIN_APP_BUNDLE_ID.onesignal</string>
	</array>
</dict>
</plist>
```

## Add the NSE Target to the Xcode Project

If a human is driving Xcode, use File ▸ New ▸ Target ▸ Notification Service Extension and name it `OneSignalNotificationServiceExtension`. When editing files directly (no Xcode UI), add the objects below to `project.pbxproj`.

ID rules: every object needs a unique 24-character hex ID. Generate IDs that do not collide with existing ones (a shared prefix plus a counter is fine). The templates use `NSE0000000000000000000X` placeholders — replace them with your generated IDs. Replace `MAIN_APP_BUNDLE_ID`, `<PROJECT_OBJECT_ID>`, and deployment-target values with the project's actual values.

### 1. Product reference

```text
NSE0000000000000000000A /* OneSignalNotificationServiceExtension.appex */ = {isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = OneSignalNotificationServiceExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; };
```

Also add this reference to the `children` list of the `Products` `PBXGroup`.

### 2. NSE native target and build phases

```text
NSE0000000000000000000E /* OneSignalNotificationServiceExtension */ = {
	isa = PBXNativeTarget;
	buildConfigurationList = NSE0000000000000000000F /* Build configuration list */;
	buildPhases = (
		NSE0000000000000000000B /* Sources */,
		NSE0000000000000000000C /* Frameworks */,
		NSE0000000000000000000D /* Resources */,
	);
	buildRules = (
	);
	dependencies = (
	);
	name = OneSignalNotificationServiceExtension;
	productName = OneSignalNotificationServiceExtension;
	productReference = NSE0000000000000000000A /* OneSignalNotificationServiceExtension.appex */;
	productType = "com.apple.product-type.app-extension";
};

NSE0000000000000000000B /* Sources */ = {
	isa = PBXSourcesBuildPhase;
	buildActionMask = 2147483647;
	files = (
	);
	runOnlyForDeploymentPostprocessing = 0;
};
NSE0000000000000000000C /* Frameworks */ = {
	isa = PBXFrameworksBuildPhase;
	buildActionMask = 2147483647;
	files = (
	);
	runOnlyForDeploymentPostprocessing = 0;
};
NSE0000000000000000000D /* Resources */ = {
	isa = PBXResourcesBuildPhase;
	buildActionMask = 2147483647;
	files = (
	);
	runOnlyForDeploymentPostprocessing = 0;
};
```

Register the target: add `NSE0000000000000000000E` to the `targets` list of the `PBXProject` object.

### 3. File group for the NSE folder

**Xcode 16+ synchronized-group projects** (the project already contains `PBXFileSystemSynchronizedRootGroup` objects): add a synchronized group so sources are picked up automatically, and exclude `Info.plist` and the entitlements file from resource copying — otherwise the build fails with "Multiple commands produce Info.plist".

```text
NSE00000000000000000012 /* OneSignalNotificationServiceExtension */ = {
	isa = PBXFileSystemSynchronizedRootGroup;
	exceptions = (
		NSE00000000000000000013 /* PBXFileSystemSynchronizedBuildFileExceptionSet */,
	);
	path = OneSignalNotificationServiceExtension;
	sourceTree = "<group>";
};
NSE00000000000000000013 /* PBXFileSystemSynchronizedBuildFileExceptionSet */ = {
	isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
	membershipExceptions = (
		Info.plist,
		OneSignalNotificationServiceExtension.entitlements,
	);
	target = NSE0000000000000000000E /* OneSignalNotificationServiceExtension */;
};
```

Then add the group to the main `PBXGroup`'s `children` and set on the NSE native target:

```text
fileSystemSynchronizedGroups = (
	NSE00000000000000000012 /* OneSignalNotificationServiceExtension */,
);
```

**Classic (non-synchronized) projects**: add `PBXFileReference` objects for `NotificationService.swift` (or `.h`/`.m`), `Info.plist`, and the entitlements file; group them in a `PBXGroup` added to the main group; and add a `PBXBuildFile` for `NotificationService.swift` to the NSE `Sources` build phase's `files` list. Do NOT add `Info.plist` or the entitlements file to any build phase.

### 4. NSE build configurations

Match the main app target's `IPHONEOS_DEPLOYMENT_TARGET`, `SWIFT_VERSION`, `DEVELOPMENT_TEAM`, and signing style. Create Debug and Release configurations (identical except the name):

```text
NSE00000000000000000010 /* Debug */ = {
	isa = XCBuildConfiguration;
	buildSettings = {
		CODE_SIGN_ENTITLEMENTS = OneSignalNotificationServiceExtension/OneSignalNotificationServiceExtension.entitlements;
		CODE_SIGN_STYLE = Automatic;
		CURRENT_PROJECT_VERSION = 1;
		GENERATE_INFOPLIST_FILE = YES;
		INFOPLIST_FILE = OneSignalNotificationServiceExtension/Info.plist;
		IPHONEOS_DEPLOYMENT_TARGET = 17.0; /* use the MAIN APP target's value, not 17.0 */
		LD_RUNPATH_SEARCH_PATHS = (
			"$(inherited)",
			"@executable_path/Frameworks",
			"@executable_path/../../Frameworks",
		);
		MARKETING_VERSION = 1.0;
		PRODUCT_BUNDLE_IDENTIFIER = MAIN_APP_BUNDLE_ID.OneSignalNotificationServiceExtension;
		PRODUCT_NAME = "$(TARGET_NAME)";
		SKIP_INSTALL = YES;
		SWIFT_EMIT_LOC_STRINGS = YES;
		SWIFT_VERSION = 5.0;
		TARGETED_DEVICE_FAMILY = "1,2";
	};
	name = Debug;
};

NSE0000000000000000000F /* Build configuration list for PBXNativeTarget "OneSignalNotificationServiceExtension" */ = {
	isa = XCConfigurationList;
	buildConfigurations = (
		NSE00000000000000000010 /* Debug */,
		NSE00000000000000000011 /* Release */,
	);
	defaultConfigurationIsVisible = 0;
	defaultConfigurationName = Release;
};
```

### 5. Wire the NSE into the main app target

```text
NSE00000000000000000016 /* PBXContainerItemProxy */ = {
	isa = PBXContainerItemProxy;
	containerPortal = <PROJECT_OBJECT_ID> /* Project object */;
	proxyType = 1;
	remoteGlobalIDString = NSE0000000000000000000E;
	remoteInfo = OneSignalNotificationServiceExtension;
};
NSE00000000000000000017 /* PBXTargetDependency */ = {
	isa = PBXTargetDependency;
	target = NSE0000000000000000000E /* OneSignalNotificationServiceExtension */;
	targetProxy = NSE00000000000000000016 /* PBXContainerItemProxy */;
};
NSE00000000000000000014 /* OneSignalNotificationServiceExtension.appex in Embed Foundation Extensions */ = {isa = PBXBuildFile; fileRef = NSE0000000000000000000A /* OneSignalNotificationServiceExtension.appex */; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };
NSE00000000000000000015 /* Embed Foundation Extensions */ = {
	isa = PBXCopyFilesBuildPhase;
	buildActionMask = 2147483647;
	dstPath = "";
	dstSubfolderSpec = 13;
	files = (
		NSE00000000000000000014 /* OneSignalNotificationServiceExtension.appex in Embed Foundation Extensions */,
	);
	name = "Embed Foundation Extensions";
	runOnlyForDeploymentPostprocessing = 0;
};
```

Then, on the MAIN APP target: append `NSE00000000000000000015 /* Embed Foundation Extensions */` to its `buildPhases` (after `Resources`) and `NSE00000000000000000017 /* PBXTargetDependency */` to its `dependencies`.

### 6. Sanity-check the edits

After editing, run `xcodebuild -list` (or open the project) — if the pbxproj is malformed it fails immediately. Both targets should be listed.

## Link the OneSignal Extension Library

The NSE target needs the iOS `OneSignalExtension` product/framework. Link it to the NSE target only; link the main app target to the app-facing OneSignal product for that SDK.

Common mappings:

* Native iOS with SPM: app target gets `OneSignalFramework` (plus recommended app products); NSE target gets `OneSignalExtension`
* Native iOS with CocoaPods: add an NSE target block for the OneSignal iOS pod
* Flutter: follow the Flutter platform section — CocoaPods projects add/update the NSE `Podfile` target; SPM projects do **not** add an NSE-only Podfile (see Flutter integrate guidance)
* Bare React Native: add/update the `ios/Podfile` NSE target block and run `pod install`
* Unity: ensure the generated Xcode project includes the NSE target and links the iOS OneSignal extension dependency after Unity exports the iOS project; build the exported **`.xcworkspace`**, not the `.xcodeproj`

### SPM projects — pbxproj objects

```text
NSE00000000000000000008 /* OneSignalExtension */ = {
	isa = XCSwiftPackageProductDependency;
	package = <ONESIGNAL_PACKAGE_REFERENCE_ID> /* XCRemoteSwiftPackageReference "OneSignal-XCFramework" */;
	productName = OneSignalExtension;
};
NSE00000000000000000009 /* OneSignalExtension in Frameworks */ = {isa = PBXBuildFile; productRef = NSE00000000000000000008 /* OneSignalExtension */; };
```

Add the `PBXBuildFile` to the NSE `Frameworks` build phase's `files` list, and add the product dependency to the NSE native target:

```text
packageProductDependencies = (
	NSE00000000000000000008 /* OneSignalExtension */,
);
```

If the project does not already reference the OneSignal package, add an `XCRemoteSwiftPackageReference` for `https://github.com/OneSignal/OneSignal-XCFramework` to the `PBXProject`'s `packageReferences` first.

### CocoaPods projects — Podfile block

Skip the SPM objects above. Add an NSE target block to the `Podfile` and run `pod install`, which generates the linking:

```ruby
target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignalXCFramework', '~> 5.0'
end
```

## Verify the iOS Infrastructure

1. Build succeeds for BOTH targets — no `No such module 'OneSignalExtension'` errors
2. The main app embeds `OneSignalNotificationServiceExtension.appex` under `PlugIns/`
3. The App Group string is byte-for-byte identical in both targets' generated entitlements
4. The main app generated `Info.plist` contains `UIBackgroundModes = remote-notification`
5. To verify end-to-end on a physical device, send a test push with an image via the REST API (`"ios_attachments": {"logo": "https://avatars.githubusercontent.com/u/11823027?s=200&v=4"}`; OneSignal sets mutable content when needed) — the image renders only if the NSE is running
6. Confirmed Delivery appears under Dashboard → Delivery → Sent Messages (requires a paid OneSignal plan; the NSE still reports it, but free plans do not display it)

## iOS Infrastructure Troubleshooting

| Issue | Solution |
| ----- | -------- |
| Push received but no image | NSE missing or not running — verify the target exists, embeds in the app, links `OneSignalExtension`, and its deployment target matches the app |
| No Confirmed Delivery stat | App Group ID mismatch, missing NSE, or plan limitation — the group must be byte-for-byte identical in both targets; dashboard display requires a paid plan |
| Badges not updating | App Groups capability missing from one of the two targets |
| `No such module 'OneSignalExtension'` | The OneSignal extension product/pod is not linked to the NSE target |
| "Multiple commands produce Info.plist" | Exclude `Info.plist` from the synchronized file group resource phase with `PBXFileSystemSynchronizedBuildFileExceptionSet` |
| App Group works in simulator but fails on device | Select a valid Apple Developer Team and let Xcode register the App Group, or configure it in the Apple Developer portal |
