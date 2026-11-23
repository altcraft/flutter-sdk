# Altcraft Flutter SDK — Target

![Altcraft SDK Logo](https://guides.altcraft.com/img/logo.svg)

[![Dart](https://img.shields.io/badge/Dart-3.6%2B-blue?style=flat-square)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue?style=flat-square)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android_iOS-green?style=flat-square)](#)
[![pub.dev](https://img.shields.io/pub/v/altcraft_target.svg?style=flat-square)](https://pub.dev/packages/altcraft_target)

Altcraft Flutter SDK is a library for interacting with the **Altcraft Marketing Platform**. The **Target** package is one of its modular components.

---

## Target

The target module is responsible for targets (goals): it sends target events to the platform to record goal achievements.

- [x] Sending target events (goal conversions) from the app.
- [x] Attaching event payloads, matching parameters, profile fields, and channel subscriptions to a target event.
- [x] Attaching UTM tags to target events for attribution.
- [x] `sendTarget` entry point matching the native SDKs.
- [x] Native event message catalog (`moduleEvents`).

---

## Dependencies

Add the **Target** package to your Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  altcraft_target: ^1.0.0
```

The Core package is included automatically as a dependency.

---

## Requirements

- Flutter 3.27+ (Dart 3.6+).
- Android 7.1+ (API 25).
- iOS 13.0+.
