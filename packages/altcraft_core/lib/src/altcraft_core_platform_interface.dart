import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:altcraft_core/altcraft_core.dart';

/// Platform interface for the Altcraft core module.
///
/// Defines the contract implemented by platform-specific code: initialization,
/// native SDK events, authentication, and data management.
abstract class AltcraftCorePlatformInterface extends PlatformInterface {
  /// Constructs a [AltcraftCorePlatformInterface].
  AltcraftCorePlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AltcraftCorePlatformInterface _instance =
      _ImplementationNotAvailable();

  /// The default instance of [AltcraftCorePlatformInterface] to use.
  static AltcraftCorePlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AltcraftCorePlatformInterface].
  static set instance(AltcraftCorePlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ---- Initialization ----

  /// Initializes the Altcraft SDK core with the given configuration.
  ///
  /// Module configurations (push notification icon, In-App placement options)
  /// are only applied when the umbrella `altcraft` package handles
  /// initialization. Core-only initialization uses native module defaults.
  Future<void> initialize(AltcraftConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  // ---- SDK Events ----

  /// Subscribes to native SDK events.
  ///
  /// Returns a broadcast stream of [SdkEvent] objects shared across callers.
  Stream<SdkEvent> subscribeToEvents() {
    throw UnimplementedError('subscribeToEvents() has not been implemented.');
  }

  /// Unsubscribes from native SDK events.
  Future<void> unsubscribeFromEvents() {
    throw UnimplementedError(
        'unsubscribeFromEvents() has not been implemented.');
  }

  // ---- State ----

  /// Clears all SDK data.
  Future<void> clear() {
    throw UnimplementedError('clear() has not been implemented.');
  }

  // ---- Session (Android) ----

  /// Unlocks initial operations in the current session (Android).
  Future<void> unlockInitialOperationsInThisSession() {
    throw UnimplementedError(
        'unlockInitialOperationsInThisSession() has not been implemented.');
  }

  // ---- UserDefaults (iOS) ----

  /// Stores a string value in native storage (UserDefaults on iOS,
  /// SharedPreferences on Android).
  ///
  /// On iOS, [suiteName] selects the App Group UserDefaults suite.
  /// On Android, [suiteName] is ignored.
  Future<void> setUserDefaultsValue(
      String? suiteName, String key, String? value) {
    throw UnimplementedError(
        'setUserDefaultsValue() has not been implemented.');
  }

  /// Sets the App Group for UserDefaults (iOS).
  Future<void> setAppGroup(String? groupName) {
    throw UnimplementedError('setAppGroup() has not been implemented.');
  }

  // ---- Authentication ----

  /// Registers a JWT provider that the native SDK calls when it needs a token.
  Future<void> setJwtProvider(Future<String?> Function() provider) {
    throw UnimplementedError('setJwtProvider() has not been implemented.');
  }

  /// Starts SDK authentication.
  Future<void> authenticate() {
    throw UnimplementedError('authenticate() has not been implemented.');
  }

  /// Logs the user out.
  Future<void> logOut() {
    throw UnimplementedError('logOut() has not been implemented.');
  }

  /// Returns whether the user is authenticated.
  Future<bool> isAuthenticated() {
    throw UnimplementedError('isAuthenticated() has not been implemented.');
  }
}

/// Throws [UnimplementedError] for all methods.
class _ImplementationNotAvailable extends AltcraftCorePlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The method ${invocation.memberName} is not available. '
      'Is the altcraft_core plugin properly installed?',
    );
  }
}
