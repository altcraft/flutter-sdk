import 'package:altcraft_core/altcraft_core.dart';
import 'altcraft_inapp_method_channel.dart';
import 'altcraft_inapp_platform_interface.dart';
import 'models/in_app_animation.dart';
import 'module_events.dart';

/// In-App module of the Altcraft SDK.
///
/// Provides In-App subscription management, screen tracking, triggers, and
/// placement requests for Android and iOS.
///
/// ```dart
/// import 'package:altcraft_inapp/altcraft_inapp.dart';
///
/// await AltcraftInApp.inAppSubscribe(sync: true);
/// await AltcraftInApp.setScreen('home');
/// await AltcraftInApp.trigger('tr_modal');
/// ```
///
/// The underlying platform implementation defaults to [MethodChannelAltcraftInApp]
/// but can be overridden for testing by setting [platform].
class AltcraftInApp {
  AltcraftInApp._();

  /// The current platform interface implementation.
  ///
  /// Can be overridden for testing with a mock implementation.
  static AltcraftInAppPlatformInterface _platform =
      MethodChannelAltcraftInApp();

  static AltcraftInAppPlatformInterface get platform => _platform;

  static set platform(AltcraftInAppPlatformInterface value) {
    _platform = value;
    AltcraftInAppPlatformInterface.instance = value;
  }

  /// In-App module event messages emitted by the native SDK.
  static const InAppModuleEvents moduleEvents = inAppModuleEvents;

  /// Subscribes to In-App notifications.
  static Future<void> inAppSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    return platform.inAppSubscribe(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// Unsubscribes from In-App notifications.
  static Future<void> inAppUnsubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    return platform.inAppUnsubscribe(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// Sets the current screen for In-App placement matching.
  static Future<void> setScreen(String screen) {
    return platform.setScreen(screen);
  }

  /// Fires an In-App trigger by name.
  static Future<void> trigger(String name) {
    return platform.trigger(name);
  }

  /// Requests available In-App placements from the server.
  static Future<void> getPlacements() {
    return platform.getPlacements();
  }

  /// Replaces the in-app view animation listener.
  ///
  /// The native SDK animates the real native view. An entry with an exact
  /// [InAppAnimation.companyId] wins; the entry with `companyId == null` is
  /// used as a fallback for campaigns without a dedicated entry. Campaigns
  /// without a match are shown without animation. An empty list disables the
  /// animation.
  ///
  /// The registration lives on the native side for the current application
  /// run; every call replaces the previous registration.
  static Future<void> setAnimations(List<InAppAnimation> animations) {
    return platform.setAnimations(animations);
  }

  /// Provides access to In-App placements with JSON content.
  ///
  /// JSON-type campaigns are not displayed by the SDK: the raw campaign JSON
  /// is delivered to the registered handler instead.
  ///
  /// ```dart
  /// AltcraftInApp.jsonContent.subscribe((json) => print(json));
  /// // ...
  /// AltcraftInApp.jsonContent.unsubscribe();
  /// ```
  static const JsonContentApi jsonContent = JsonContentApi._();
}

/// Provides access to In-App placements with JSON content.
///
/// JSON-type campaigns are not displayed by the SDK: the raw campaign JSON is
/// delivered to the registered handler instead. The native SDKs support a
/// single subscriber, so a new [subscribe] call replaces the previous handler.
class JsonContentApi {
  const JsonContentApi._();

  /// Registers a handler receiving raw JSON content.
  Future<void> subscribe(void Function(String json) handler) {
    return AltcraftInApp.platform.jsonContentSubscribe(handler);
  }

  /// Removes the current handler.
  Future<void> unsubscribe() {
    return AltcraftInApp.platform.jsonContentUnsubscribe();
  }
}
