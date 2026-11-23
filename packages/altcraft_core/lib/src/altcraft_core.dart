import 'package:altcraft_core/altcraft_core.dart';

/// Core module of the Altcraft SDK.
///
/// Provides SDK initialization, native SDK events, JWT authentication, and
/// data management. All other Altcraft modules depend on this module.
///
/// ```dart
/// import 'package:altcraft_core/altcraft_core.dart';
///
/// await AltcraftCore.initialize(AltcraftConfig(
///   apiUrl: 'https://your-api.altcraft.com',
/// ));
///
/// AltcraftCore.subscribeToEvents().listen((event) {
///   print('${event.function}: ${event.message}');
/// });
/// ```
///
/// Module-specific options are added through builder extensions provided by
/// the corresponding module packages:
///
/// ```dart
/// import 'package:altcraft_inapp/altcraft_inapp.dart';
/// import 'package:altcraft_push/altcraft_push.dart';
///
/// await AltcraftCore.initialize(
///   AltcraftConfigBuilder(apiUrl: 'https://your-api.altcraft.com')
///       .pushConfig(const PushConfig(providerPriority: ['android-firebase']))
///       .inAppConfig(const InAppConfig())
///       .build(),
/// );
/// ```
///
/// The core module does not depend on concrete modules: it forwards their
/// configurations to the native SDK at initialization.
///
/// The underlying platform implementation defaults to [MethodChannelAltcraftCore]
/// but can be overridden for testing by setting [platform].
class AltcraftCore {
  AltcraftCore._();

  /// The current platform interface implementation.
  ///
  /// Can be overridden for testing with a mock implementation.
  static AltcraftCorePlatformInterface _platform = MethodChannelAltcraftCore();

  static AltcraftCorePlatformInterface get platform => _platform;

  static set platform(AltcraftCorePlatformInterface value) {
    _platform = value;
    AltcraftCorePlatformInterface.instance = value;
  }

  /// Core module event messages emitted by the native SDK.
  static const CoreModuleEvents moduleEvents = coreModuleEvents;

  // ---- Initialization ----

  /// Initializes the Altcraft SDK core with the given configuration.
  ///
  /// Module-specific options are contributed by module packages through
  /// [AltcraftConfigBuilder] extensions (for example
  /// `AltcraftConfigBuilder.pushConfig`). The core module forwards them to the
  /// native SDK without interpreting the contents.
  static Future<void> initialize(AltcraftConfig config) {
    return platform.initialize(config);
  }

  // ---- SDK Events ----

  /// Subscribes to native SDK events.
  ///
  /// Returns a broadcast stream of [SdkEvent] objects. Multiple listeners can
  /// subscribe to the same underlying native event source. Call
  /// [unsubscribeFromEvents] to stop all event delivery.
  static Stream<SdkEvent> subscribeToEvents() {
    return platform.subscribeToEvents();
  }

  /// Unsubscribes from native SDK events.
  static Future<void> unsubscribeFromEvents() {
    return platform.unsubscribeFromEvents();
  }

  // ---- State ----

  /// Clears all SDK data.
  static Future<void> clear() {
    return platform.clear();
  }

  // ---- Session (Android) ----

  /// Unlocks initial operations in the current session (Android only).
  ///
  /// On iOS the call is a no-op — the native iOS SDK has no such operation.
  static Future<void> unlockInitialOperationsInThisSession() {
    return platform.unlockInitialOperationsInThisSession();
  }

  // ---- UserDefaults (iOS) ----

  /// Stores a string value in native storage (UserDefaults on iOS,
  /// SharedPreferences on Android).
  ///
  /// On iOS, [suiteName] selects the App Group UserDefaults suite.
  /// On Android, [suiteName] is ignored.
  static Future<void> setUserDefaultsValue(
      String? suiteName, String key, String? value) {
    return platform.setUserDefaultsValue(suiteName, key, value);
  }

  /// Sets the App Group for UserDefaults (iOS).
  static Future<void> setAppGroup(String? groupName) {
    return platform.setAppGroup(groupName);
  }

  // ---- Authentication ----

  /// Registers a JWT provider that the native SDK calls when it needs a token.
  ///
  /// The [provider] callback is invoked over the method channel whenever the
  /// native SDK requests the current JWT token.
  static Future<void> setJwtProvider(Future<String?> Function() provider) {
    return platform.setJwtProvider(provider);
  }

  /// Starts SDK authentication.
  static Future<void> authenticate() {
    return platform.authenticate();
  }

  /// Logs the user out.
  static Future<void> logOut() {
    return platform.logOut();
  }

  /// Returns whether the user is authenticated.
  static Future<bool> isAuthenticated() {
    return platform.isAuthenticated();
  }
}
