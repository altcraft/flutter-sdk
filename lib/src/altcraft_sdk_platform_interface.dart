import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/altcraft_config.dart';
import 'models/sdk_event.dart';
import 'models/token_data.dart';
import 'models/response_with_http_code.dart';

/// Platform interface for the Altcraft SDK plugin.
///
/// This abstract class defines the contract that platform-specific
/// implementations must fulfill. The default implementation uses
/// [MethodChannel] for communication with native code.
abstract class AltcraftSdkPlatformInterface extends PlatformInterface {
  /// Constructs a AltcraftSdkPlatformInterface.
  AltcraftSdkPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AltcraftSdkPlatformInterface _instance =
      _ImplementationNotAvailable();

  /// The default instance of [AltcraftSdkPlatformInterface] to use.
  static AltcraftSdkPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AltcraftSdkPlatformInterface].
  static set instance(AltcraftSdkPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ---- Initialization ----

  /// Initializes the Altcraft SDK with the given configuration.
  Future<void> initialize(AltcraftConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  // ---- Push Subscription ----

  /// Subscribes to push notifications.
  void pushSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('pushSubscribe() has not been implemented.');
  }

  /// Suspends push subscription.
  void pushSuspend({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('pushSuspend() has not been implemented.');
  }

  /// Unsubscribes from push notifications.
  void pushUnSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('pushUnSubscribe() has not been implemented.');
  }

  /// UnSuspends a previously suspended push subscription.
  Future<ResponseWithHttpCode?> unSuspendPushSubscription() {
    throw UnimplementedError('unSuspendPushSubscription() has not been implemented.');
  }

  // ---- Subscription Status ----

  /// Gets the status of the latest subscription.
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscription() {
    throw UnimplementedError('getStatusOfLatestSubscription() has not been implemented.');
  }

  /// Gets the status of the current subscription.
  Future<ResponseWithHttpCode?> getStatusForCurrentSubscription() {
    throw UnimplementedError('getStatusForCurrentSubscription() has not been implemented.');
  }

  /// Gets the status of the latest subscription for a specific provider.
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscriptionForProvider(String? provider) {
    throw UnimplementedError('getStatusOfLatestSubscriptionForProvider() has not been implemented.');
  }

  // ---- SDK Events ----

  /// Subscribes to SDK events stream.
  Stream<SdkEvent> subscribeToEvents() {
    throw UnimplementedError('subscribeToEvents() has not been implemented.');
  }

  /// Unsubscribes from SDK events.
  Future<void> unsubscribeFromEvents() {
    throw UnimplementedError('unsubscribeFromEvents() has not been implemented.');
  }

  // ---- Mobile Events ----

  /// Sends a mobile event to the Altcraft platform.
  void mobileEvent({
    required String sid,
    required String eventName,
    String? sendMessageId,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? matching,
    String? matchingType,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? subscription,
    Map<String, dynamic>? utm,
  }) {
    throw UnimplementedError('mobileEvent() has not been implemented.');
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

  // ---- State ----

  /// Clears all SDK state.
  Future<void> clear() {
    throw UnimplementedError('clear() has not been implemented.');
  }

  // ---- Push Handling (Android) ----

  /// Forwards a push payload to the SDK (Android).
  void takePush(Map<String, String> message) {
    throw UnimplementedError('takePush() has not been implemented.');
  }

  // ---- Permissions (Android) ----

  /// Requests notification permission (Android).
  Future<bool> requestNotificationPermission() async {
    throw UnimplementedError('requestNotificationPermission() has not been implemented.');
  }

  // ---- Push Events (Android) ----

  /// Reports push delivery (Android).
  void deliveryEvent(Map<String, String>? message, String? messageUID) {
    throw UnimplementedError('deliveryEvent() has not been implemented.');
  }

  /// Reports push open (Android).
  void openEvent(Map<String, String>? message, String? messageUID) {
    throw UnimplementedError('openEvent() has not been implemented.');
  }

  // ---- UserDefaults (iOS) ----

  /// Stores a value in native storage (UserDefaults on iOS, SharedPreferences on Android).
  void setUserDefaultsValue(String? suiteName, String key, dynamic value) {
    throw UnimplementedError('setUserDefaultsValue() has not been implemented.');
  }

  // ---- Profile ----

  /// Updates profile fields on the server.
  void updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('updateProfileFields() has not been implemented.');
  }

  // ---- Token Management ----

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
    throw UnimplementedError('changePushProviderPriorityList() has not been implemented.');
  }

  // ---- Push Identification ----

  /// Checks if a push message is from Altcraft.
  Future<bool> isAltcraftPush(Map<String, String> message) async {
    throw UnimplementedError('isAltcraftPush() has not been implemented.');
  }

  // ---- Session (Android) ----

  /// Unlocks initial operations in the current session (Android).
  void unlockInitialOperationsInThisSession() {
    throw UnimplementedError('unlockInitialOperationsInThisSession() has not been implemented.');
  }

  // ---- App Group (iOS) ----

  /// Sets the App Group for UserDefaults (iOS).
  void setAppGroup(String? groupName) {
    throw UnimplementedError('setAppGroup() has not been implemented.');
  }
}

/// Throws [UnimplementedError] for all methods.
class _ImplementationNotAvailable extends AltcraftSdkPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The method ${invocation.memberName} is not available. '
      'Is the altcraft_sdk plugin properly installed?',
    );
  }
}
