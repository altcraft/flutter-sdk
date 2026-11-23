# Altcraft Flutter SDK — Push

![Altcraft SDK Logo](https://guides.altcraft.com/img/logo.svg)

[![Dart](https://img.shields.io/badge/Dart-3.6%2B-blue?style=flat-square)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue?style=flat-square)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android_iOS-green?style=flat-square)](#)
[![pub.dev](https://img.shields.io/pub/v/altcraft_push.svg?style=flat-square)](https://pub.dev/packages/altcraft_push)

Altcraft Flutter SDK is a library for interacting with the **Altcraft Marketing Platform**. The **Push** package is one of its modular components.

---

## Push

The push module is responsible for push notifications.

- [x] Push subscription management: subscribe, suspend, unsubscribe.
- [x] Automatic display of push notifications configured in the platform.
- [x] Push token management: automatic update when the token changes, manual token operations.
- [x] Automatic transmission of notification delivery and open events.
- [x] Support for push providers: APNs, Firebase, Huawei, RuStore (platform-dependent).
- [x] Custom push notification handling and access to all message data fields.
- [x] Notification permission request for Android 13+ devices.
- [x] Native event message catalog (`moduleEvents`).

---

## Dependencies

Add the **Push** package to your Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  altcraft_push: ^1.0.0
```

The Core package is included automatically as a dependency. A configured push provider is required: Firebase, Huawei, or RuStore on Android; APNs on iOS.

---

## Requirements

- Flutter 3.27+ (Dart 3.6+).
- Android 7.1+ (API 25).
- iOS 13.0+.
