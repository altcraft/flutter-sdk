# Changelog

All notable changes to the Altcraft Flutter SDK are documented in this file.

## 2.0.0

- Module initialization options are configured through `AltcraftCore.initialize`
  with `AltcraftConfigBuilder` and module builder extensions (`pushConfig`,
  `inAppConfig`), mirroring the native `AltcraftConfiguration.Builder`
  extensions. `AltcraftConfig` now carries core parameters only; the core
  module forwards generic module configurations without depending on concrete
  modules.
- The full SDK umbrella package is renamed to `altcraft_sdk` and released as
  2.0.0, replacing the monolithic `altcraft_sdk` 1.0.0. The Dart API is
  backward compatible: all `AltcraftSDK` methods and models from 1.0.0 are
  preserved; In-App, authentication, and In-App screen/trigger/placement
  methods as well as the module packages were added.
- App integration changes compared to 1.0.0: on iOS the native SDK is
  integrated via Swift Package Manager (`github.com/altcraft/ios-sdk` from
  2.0.1) instead of the CocoaPods `Altcraft` 1.0.3 pod — Swift Package
  Manager support must be enabled in the app; on Android the native
  dependency moved from the monolithic `com.altcraft:android-sdk:1.0.6` to
  the modular `com.altcraft:android-sdk-*:1.0.1` artifacts, which are
  resolved automatically.
- Modular architecture: the SDK is split into independent pub.dev packages
  mirroring the native Altcraft SDK modules: `altcraft_core`, `altcraft_push`,
  `altcraft_inapp`, `altcraft_target`, `altcraft_profile` (1.0.0 each).
- Native dependencies: Maven Central `com.altcraft:android-sdk-*:1.0.1`
  (Core included transitively), Swift Package Manager
  `https://github.com/altcraft/ios-sdk` from 2.0.1.
- iOS integration via Swift Package Manager.
- One method channel per module (`com.altcraft/core`, `com.altcraft/push`,
  `com.altcraft/inapp`, `com.altcraft/target`, `com.altcraft/profile`),
  umbrella channel `com.altcraft/sdk` handles full initialization.
- SDK event stream shared through the `com.altcraft/events` channel.
- Repository structured as a Melos-managed monorepo with a shared pub
  workspace.

## 1.0.0

- Initial release
- Full SDK bridge for Android (1.0.6) and iOS (1.0.3)
- 26 SDK methods: initialize, pushSubscribe, pushSuspend, pushUnSubscribe, unSuspendPushSubscription, getStatusOfLatestSubscription, getStatusOfLatestSubscriptionForProvider, getStatusForCurrentSubscription, getPushToken, setPushToken, clear, mobileEvent, subscribeToEvents, unsubscribeFromEvent, takePush, requestNotificationPermission, deliveryEvent, openEvent, setUserDefaultsValue, updateProfileFields, forcedTokenUpdate, deleteDeviceToken, changePushProviderPriorityList, isAltcraftPush, unlockInitialOperationsInThisSession, setAppGroup
- Event stream via EventChannel
- ActionFieldBuilder utility
- Platform interface for testability
