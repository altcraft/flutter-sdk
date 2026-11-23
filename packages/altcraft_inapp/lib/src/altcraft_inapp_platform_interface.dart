import 'package:altcraft_core/altcraft_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/in_app_animation.dart';

/// Platform interface for the Altcraft In-App module.
abstract class AltcraftInAppPlatformInterface extends PlatformInterface {
  /// Constructs a [AltcraftInAppPlatformInterface].
  AltcraftInAppPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AltcraftInAppPlatformInterface _instance =
      _ImplementationNotAvailable();

  /// The default instance of [AltcraftInAppPlatformInterface] to use.
  static AltcraftInAppPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AltcraftInAppPlatformInterface].
  static set instance(AltcraftInAppPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Subscribes to In-App notifications.
  Future<void> inAppSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('inAppSubscribe() has not been implemented.');
  }

  /// Unsubscribes from In-App notifications.
  Future<void> inAppUnsubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('inAppUnsubscribe() has not been implemented.');
  }

  /// Sets the current screen for In-App placement matching.
  Future<void> setScreen(String screen) {
    throw UnimplementedError('setScreen() has not been implemented.');
  }

  /// Fires an In-App trigger by name.
  Future<void> trigger(String name) {
    throw UnimplementedError('trigger() has not been implemented.');
  }

  /// Requests available In-App placements from the server.
  Future<void> getPlacements() {
    throw UnimplementedError('getPlacements() has not been implemented.');
  }

  /// Replaces the in-app view animation listener.
  Future<void> setAnimations(List<InAppAnimation> animations) {
    throw UnimplementedError('setAnimations() has not been implemented.');
  }

  /// Registers a handler receiving raw JSON content of JSON-content In-App
  /// campaigns.
  ///
  /// The native SDK keeps a single subscriber, so a new registration replaces
  /// the previous handler.
  Future<void> jsonContentSubscribe(void Function(String json) handler) {
    throw UnimplementedError(
        'jsonContentSubscribe() has not been implemented.');
  }

  /// Removes the current JSON content handler.
  Future<void> jsonContentUnsubscribe() {
    throw UnimplementedError(
        'jsonContentUnsubscribe() has not been implemented.');
  }
}

/// Throws [UnimplementedError] for all methods.
class _ImplementationNotAvailable extends AltcraftInAppPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The method ${invocation.memberName} is not available. '
      'Is the altcraft_inapp plugin properly installed?',
    );
  }
}
