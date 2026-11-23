# Altcraft Flutter SDK — In-App

![Altcraft SDK Logo](https://guides.altcraft.com/img/logo.svg)

[![Dart](https://img.shields.io/badge/Dart-3.6%2B-blue?style=flat-square)](https://dart.dev/)

[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue?style=flat-square)](https://flutter.dev/)

[![Platforms](https://img.shields.io/badge/Platforms-Android_iOS-green?style=flat-square)](#)

[![pub.dev](https://img.shields.io/pub/v/altcraft_inapp.svg?style=flat-square)](https://pub.dev/packages/altcraft_inapp)

Altcraft Flutter SDK is a library for interacting with the **Altcraft Marketing Platform**. The **In-App** package is one of its modular components.

---

## In-App

The in-app module is responsible for in-app campaigns.

- [x] Automatic display of in-app campaigns configured in the platform.
- [x] In-App subscription management: subscribe and unsubscribe.
- [x] Placement requests, current screen matching, and custom triggers.
- [x] JSON in-app campaign emission to an external subscriber.
- [x] In-app view animation customization (fade, offset, scale per campaign).
- [x] JSON content subscription (`jsonContent`).
- [x] Native event message catalog (`moduleEvents`).

---

## Dependencies

Add the **In-App** package to your Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  altcraft_inapp: ^1.0.0
```

The Core package is included automatically as a dependency.

---

## Requirements

- Flutter 3.27+ (Dart 3.6+).
- Android 7.1+ (API 25).
- iOS 13.0+.
