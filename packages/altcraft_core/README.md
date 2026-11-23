# Altcraft Flutter SDK — Core

![Altcraft SDK Logo](https://guides.altcraft.com/img/logo.svg)

[![Dart](https://img.shields.io/badge/Dart-3.6%2B-blue?style=flat-square)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue?style=flat-square)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android_iOS-green?style=flat-square)](#)
[![pub.dev](https://img.shields.io/pub/v/altcraft_core.svg?style=flat-square)](https://pub.dev/packages/altcraft_core)

Altcraft Flutter SDK is a library for interacting with the **Altcraft Marketing Platform**. The **Core** package is one of its modular components.

---

## Core

The core is the foundation of the SDK: it connects your application to the Altcraft platform and makes the optional modules available.

- [x] SDK initialization and configuration.
- [x] Authentication with JWT or a role token (**RToken**).
- [x] Works with anonymous and registered users; supports multiple profiles on one device (JWT).
- [x] Transmission of requests to the platform with automatic retry of failed requests.
- [x] SDK event stream for monitoring SDK behavior in the app.
- [x] Native event message catalog per module (`moduleEvents`).
- [x] SDK data cleanup and background tasks termination.

---

## Dependencies

Add the **Core** package to your Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  altcraft_core: ^1.0.0
```

---

## Requirements

- Flutter 3.27+ (Dart 3.6+).
- Android 7.1+ (API 25).
- iOS 13.0+.
