# Altcraft Flutter SDK

![Altcraft SDK Logo](https://guides.altcraft.com/img/logo.svg)

[![Dart](https://img.shields.io/badge/Dart-3.6%2B-blue?style=flat-square)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue?style=flat-square)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android_iOS-green?style=flat-square)](#)
[![pub.dev](https://img.shields.io/pub/v/altcraft_sdk.svg?style=flat-square)](https://pub.dev/packages/altcraft_sdk)

Altcraft Flutter SDK is a library for interacting with the **Altcraft Marketing Platform**. It uses a modular architecture in which each component provides a specific set of capabilities.

---

## SDK Modules

### Core

The Core module is the foundation of the SDK: it connects your application to the Altcraft platform and makes the optional modules available.

* [x] SDK initialization and configuration.
* [x] Authentication with JWT or a role token (*rToken*).
* [x] Works with anonymous and registered users; supports multiple profiles on one device (JWT).
* [x] Transmission of requests to the platform with automatic retry of failed requests.
* [x] SDK event stream for monitoring SDK behavior in the app.
* [x] Native event message catalog per module (`moduleEvents`).
* [x] SDK data cleanup and background tasks termination.

### Push

The push module is responsible for push notifications.

* [x] Push subscription management: subscribe, suspend, unsubscribe.
* [x] Automatic display of push notifications configured in the platform.
* [x] Push token management: automatic update when the token changes, manual token operations.
* [x] Automatic transmission of notification delivery and open events.
* [x] Support for push providers: APNs, Firebase, Huawei, RuStore (platform-dependent).
* [x] Custom push notification handling and access to all message data fields.
* [x] Notification permission request for Android 13+ devices.
* [x] Native event message catalog (`moduleEvents`).

### Target

The target module is responsible for mobile events: it sends target events to the platform to record goal achievements.

* [x] Sending target events (goal conversions) from the app.
* [x] Attaching event payloads, matching parameters, profile fields, and channel subscriptions to a target event.
* [x] Attaching UTM tags to target events for attribution.
* [x] `sendTarget` entry point matching the native SDKs.
* [x] Native event message catalog (`moduleEvents`).

### Profile

The profile module is responsible for user profile fields.

* [x] Updating profile fields from the app.
* [x] Native event message catalog (`moduleEvents`).

### In-App

The in-app module is responsible for in-app campaigns.

* [x] Automatic display of in-app campaigns configured in the platform.
* [x] In-app subscription management: subscribe, unsubscribe, status retrieval.
* [x] Placement requests, current screen matching, and custom triggers.
* [x] In-app view animation customization (fade, offset, scale per campaign).
* [x] Native event message catalog (`moduleEvents`).

---

## Dependencies

Altcraft Flutter SDK modules are distributed via pub.dev. Add the modules used by your application. The Core package is included automatically as a dependency of other SDK modules and does not need to be added separately.

**pub.dev:**

```yaml
dependencies:
  altcraft_push: ^1.0.0
  altcraft_inapp: ^1.0.0
  altcraft_target: ^1.0.0
  altcraft_profile: ^1.0.0
```

If you only need Core, add the `altcraft_core` package directly (`altcraft_core: ^1.0.0`).

Alternatively, add the umbrella package to use the full SDK:

```yaml
dependencies:
  altcraft_sdk: ^2.0.0
```
---

## Authorization Types

### JWT-Authorization (recommended approach)

JWT is added to the header of every request. The SDK requests the current token from the app via the registered JWT provider.

**Advantages:**

* Enhanced security of API requests.
* Profile lookup by any identifier (email, phone, custom ID).
* Support for multiple users on a single device.
* Profile persists after app reinstallation.
* Unified user identity across devices.

### Authorization with a role token (*rToken*)

The role token is specified in the SDK configuration.
Profile lookup is limited to the push token identifier.

**Limitations:**

* The link to a profile may be lost if the push token changes and the change isn’t reflected on the platform.
* No multi-profile support.
* It’s not possible to register the same user on another device.

---

## Requirements

* Flutter 3.27+ (Dart 3.6+).
* Android 7.1+ (API 25).
* iOS 13.0+.
* A configured push provider (Firebase, Huawei, RuStore on Android; APNs on iOS) when using the Push module.

---

## Documentation

Detailed information on SDK setup, functionality, and usage is available on the Altcraft documentation portal:

- [**Altcraft Flutter SDK**](https://guides.altcraft.com/en/developer-guide/sdk/mobile/flutter/)

---

## License

### EULA

END USER LICENSE AGREEMENT

Copyright © 2026 Altcraft LLC. All rights reserved.

1. LICENSE GRANT
   This agreement grants you certain rights to use the Altcraft Mobile SDK (hereinafter referred to as the “Software”).
   All rights not expressly granted by this agreement remain with the copyright holder.

2. USE
   You are permitted to use and distribute the Software for both commercial and non-commercial purposes.

3. MODIFICATION WITHOUT PUBLICATION
   You may modify the Software for your own internal purposes without any obligation to publish such modifications.

4. MODIFICATION WITH PUBLICATION
   Publication of modified Software requires prior written permission from the copyright holder.

5. DISCLAIMER OF WARRANTIES
   The Software is provided “as is,” without any warranties, express or implied, including but not limited to
   warranties of merchantability, fitness for a particular purpose, and non-infringement of third-party rights.

6. LIMITATION OF LIABILITY
   Under no circumstances shall the copyright holder be liable for any direct, indirect, incidental, special,
   punitive, or consequential damages (including but not limited to: procurement of substitute goods or services;
   loss of data, profits, or business interruption) arising in any way from the use of this Software,
   even if the copyright holder has been advised of the possibility of such damages.

7. DISTRIBUTION
   When distributing the Software, you must provide all recipients with a copy of this license agreement.

8. COPYRIGHT AND THIRD-PARTY COMPONENTS
   This Software may include components distributed under other licenses. The full list of such components
   and their respective licenses is provided below:

### Third-party libraries and licenses

**Apache License 2.0**
Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

* [Kotlin](https://github.com/JetBrains/kotlin)
* [KotlinX Serialization](https://github.com/Kotlin/kotlinx.serialization)
* [KotlinX Coroutines](https://github.com/Kotlin/kotlinx.coroutines)
* [Retrofit](https://github.com/square/retrofit)
* [OkHttp](https://github.com/square/okhttp)
* [AndroidX Annotation](https://developer.android.com/jetpack/androidx/releases/annotation)
* [AndroidX Core](https://developer.android.com/jetpack/androidx/releases/core)
* [AndroidX Room](https://developer.android.com/jetpack/androidx/releases/room)
* [WorkManager](https://developer.android.com/jetpack/androidx/releases/work)
* [AndroidX Lifecycle](https://developer.android.com/jetpack/androidx/releases/lifecycle)
* [AndroidX Startup](https://developer.android.com/jetpack/androidx/releases/startup)
* [AndroidX DataStore](https://developer.android.com/jetpack/androidx/releases/datastore)

**Other licenses:**

* [Flutter](https://github.com/flutter/flutter) — **BSD-3-Clause**
* [Glide](https://github.com/bumptech/glide) — **BSD-2-Clause**
* [JUnit 4](https://junit.org/junit4/) — **EPL-1.0 (Eclipse Public License 1.0)**
* [Google Play Services Ads Identifier](https://developers.google.com/android/reference/com/google/android/gms/ads/identifier/AdvertisingIdClient) — subject to [Google Play Services SDK License Agreement](https://developers.google.com/terms)
