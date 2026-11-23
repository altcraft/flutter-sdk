import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'models/token_data.dart';

/// Platform interface for the Altcraft push module.
abstract class AltcraftPushPlatformInterface extends PlatformInterface {
  /// Constructs a [AltcraftPushPlatformInterface].
  AltcraftPushPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AltcraftPushPlatformInterface _instance =
      _ImplementationNotAvailable();

  /// The default instance of [AltcraftPushPlatformInterface] to use.
  static AltcraftPushPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AltcraftPushPlatformInterface].
  static set instance(AltcraftPushPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ---- Push Subscription ----

  /// Subscribes to push notifications.
  Future<void> pushSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('pushSubscribe() has not been implemented.');
  }

  /// Suspends push subscription.
  Future<void> pushSuspend({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('pushSuspend() has not been implemented.');
  }

  /// Unsubscribes from push notifications.
  Future<void> pushUnSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('pushUnSubscribe() has not been implemented.');
  }

  /// UnSuspends a previously suspended push subscription.
  Future<ResponseWithHttpCode?> unSuspendPushSubscription() {
    throw UnimplementedError(
        'unSuspendPushSubscription() has not been implemented.');
  }

  // ---- Subscription Status ----

  /// Gets the status of the latest subscription.
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscription() {
    throw UnimplementedError(
        'getStatusOfLatestSubscription() has not been implemented.');
  }

  /// Gets the status of the current subscription.
  Future<ResponseWithHttpCode?> getStatusForCurrentSubscription() {
    throw UnimplementedError(
        'getStatusForCurrentSubscription() has not been implemented.');
  }

  /// Gets the status of the latest subscription for a specific provider.
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscriptionForProvider(
      String? provider) {
    throw UnimplementedError(
        'getStatusOfLatestSubscriptionForProvider() has not been implemented.');
  }

  // ---- Push Tokens ----

  /// Gets the current push token data.
  Future<TokenData?> getPushToken() {
    throw UnimplementedError('getPushToken() has not been implemented.');
  }

  /// Sets or clears a push token for the given provider.
  Future<void> setPushToken(String provider, String? token) {
    throw UnimplementedError('setPushToken() has not been implemented.');
  }

  /// Forces a token refresh.
  Future<void> forcedTokenUpdate() {
    throw UnimplementedError('forcedTokenUpdate() has not been implemented.');
  }

  /// Deletes a device token for the given provider.
  Future<void> deleteDeviceToken(String provider) {
    throw UnimplementedError('deleteDeviceToken() has not been implemented.');
  }

  /// Changes the push provider priority list.
  Future<void> changePushProviderPriorityList(List<String> priorityList) {
    throw UnimplementedError(
        'changePushProviderPriorityList() has not been implemented.');
  }

  // ---- Push Handling (Android) ----

  /// Forwards a push payload to the SDK (Android).
  Future<void> takePush(Map<String, String> message) {
    throw UnimplementedError('takePush() has not been implemented.');
  }

  /// Checks if a push message is from Altcraft.
  Future<bool> isAltcraftPush(Map<String, String> message) async {
    throw UnimplementedError('isAltcraftPush() has not been implemented.');
  }

  // ---- Permissions (Android) ----

  /// Requests notification permission (Android).
  /// Returns true if granted, false if denied.
  Future<bool> requestNotificationPermission() async {
    throw UnimplementedError(
        'requestNotificationPermission() has not been implemented.');
  }

  // ---- Push Events (Android) ----

  /// Reports push delivery (Android).
  Future<void> deliveryEvent(Map<String, String>? message, String? messageUID) {
    throw UnimplementedError('deliveryEvent() has not been implemented.');
  }

  /// Reports push open (Android).
  Future<void> openEvent(Map<String, String>? message, String? messageUID) {
    throw UnimplementedError('openEvent() has not been implemented.');
  }
}

/// Throws [UnimplementedError] for all methods.
class _ImplementationNotAvailable extends AltcraftPushPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The method ${invocation.memberName} is not available. '
      'Is the altcraft_push plugin properly installed?',
    );
  }
}
