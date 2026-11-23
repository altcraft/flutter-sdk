# Altcraft Flutter SDK — Full SDK

![Altcraft SDK Logo](https://guides.altcraft.com/img/logo.svg)

[![Dart](https://img.shields.io/badge/Dart-3.6%2B-blue?style=flat-square)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue?style=flat-square)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android_iOS-green?style=flat-square)](#)
[![pub.dev](https://img.shields.io/pub/v/altcraft_sdk.svg?style=flat-square)](https://pub.dev/packages/altcraft_sdk)

Altcraft Flutter SDK is a library for interacting with the **Altcraft Marketing Platform**. The **Full SDK** package combines all modular components into a single dependency.

---

## SDK Modules

The `altcraft_sdk` package includes:

- **Core**: SDK initialization, authentication, events, and data management.
- **Push**: push subscriptions, tokens, providers, and notification events.
- **In-App**: in-app subscriptions, placements, screens, triggers, and JSON content.
- **Target**: target events with payload, matching, subscriptions, and UTM data.
- **Profile**: profile field updates.
- All modules expose their native event catalog through the module event catalog (`moduleEvents`).

---

## Dependencies

Add the **Full SDK** package to your Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  altcraft_sdk: ^2.0.0
```

The package includes all modules and links the native Altcraft SDK components automatically. To depend only on the modules used by the application, use the individual `altcraft_*` packages instead.

---

## Requirements

- Flutter 3.27+ (Dart 3.6+).
- Android 7.1+ (API 25).
- iOS 13.0+.
- A configured push provider (Firebase, Huawei, RuStore on Android; APNs on iOS) when using the Push module.
