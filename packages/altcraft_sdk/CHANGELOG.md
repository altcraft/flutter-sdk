## 2.0.0

- Module initialization options are now configured through `AltcraftCore.initialize` with `AltcraftConfigBuilder` and module builder extensions (`pushConfig`, `inAppConfig`), mirroring the native `AltcraftConfiguration.Builder` extensions. The core module no longer knows about concrete modules.
- `AltcraftConfig` carries core parameters only; the push-specific fields were moved to `PushConfig` (`altcraft_push`), and the In-App options to `InAppConfig` (`altcraft_inapp`).
- In-App view animation now mirrors the native bridge capabilities: `setInAppAnimations` takes `InAppAnimation` entries with independent `scaleX`/`scaleY`, target (`*To`) values, `rotation`, and 350 ms / `easeInOut` defaults.
- Subscription, In-App and target parameters are strongly typed: `cats` accepts `List<CategoryData>`, `sendTarget` accepts `Subscription` and `UTM`.
- The umbrella package is renamed to `altcraft_sdk` and released as 2.0.0,
  replacing the monolithic `altcraft_sdk` 1.0.0. The Dart API is backward
  compatible: all `AltcraftSDK` methods and models from 1.0.0 are preserved;
  In-App, authentication, and In-App screen/trigger/placement methods as well
  as the module packages were added.
- App integration changes compared to 1.0.0: on iOS the native SDK is
  integrated via Swift Package Manager (`github.com/altcraft/ios-sdk` from
  2.0.1) instead of the CocoaPods `Altcraft` 1.0.3 pod — Swift Package
  Manager support must be enabled in the app; on Android the native
  dependency moved from the monolithic `com.altcraft:android-sdk:1.0.6` to
  the modular `com.altcraft:android-sdk-*:1.0.1` artifacts, which are
  resolved automatically.
- Modular architecture under the hood: the SDK delegates to the independent
  pub.dev packages `altcraft_core`, `altcraft_push`, `altcraft_inapp`,
  `altcraft_target`, `altcraft_profile`.
- Target events are sent with `sendTarget` (renamed from `mobileEvent`),
  matching the native SDKs and the React Native SDK.
- Every module exposes the native event message catalog via `moduleEvents`.
- Complete SDK initialization with push and In-App module options.
- Native dependencies: Maven Central `com.altcraft:android-sdk-*:1.0.1`,
  Swift Package Manager `github.com/altcraft/ios-sdk` from 2.0.1.
