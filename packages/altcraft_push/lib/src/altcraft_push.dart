import 'altcraft_push_method_channel.dart';
import 'altcraft_push_platform_interface.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'models/token_data.dart';
import 'module_events.dart';

/// Push module of the Altcraft SDK.
///
/// Provides push subscription management, push token handling, provider
/// priority management, and push event reporting for Android and iOS.
///
/// ```dart
/// import 'package:altcraft_push/altcraft_push.dart';
///
/// await AltcraftPush.pushSubscribe(sync: true);
/// final token = await AltcraftPush.getPushToken();
/// ```
///
/// The underlying platform implementation defaults to [MethodChannelAltcraftPush]
/// but can be overridden for testing by setting [platform].
class AltcraftPush {
  AltcraftPush._();

  /// The current platform interface implementation.
  ///
  /// Can be overridden for testing with a mock implementation.
  static AltcraftPushPlatformInterface _platform = MethodChannelAltcraftPush();

  static AltcraftPushPlatformInterface get platform => _platform;

  static set platform(AltcraftPushPlatformInterface value) {
    _platform = value;
    AltcraftPushPlatformInterface.instance = value;
  }

  /// Push module event messages emitted by the native SDK.
  static const PushModuleEvents moduleEvents = pushModuleEvents;

  // ---- Push Subscription ----

  /// Subscribes to push notifications.
  static Future<void> pushSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    return platform.pushSubscribe(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// Suspends push subscription.
  static Future<void> pushSuspend({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    return platform.pushSuspend(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// Unsubscribes from push notifications.
  static Future<void> pushUnSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    return platform.pushUnSubscribe(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// UnSuspends a previously suspended push subscription.
  static Future<ResponseWithHttpCode?> unSuspendPushSubscription() {
    return platform.unSuspendPushSubscription();
  }

  // ---- Subscription Status ----

  /// Gets the status of the latest subscription.
  static Future<ResponseWithHttpCode?> getStatusOfLatestSubscription() {
    return platform.getStatusOfLatestSubscription();
  }

  /// Gets the status of the current subscription.
  static Future<ResponseWithHttpCode?> getStatusForCurrentSubscription() {
    return platform.getStatusForCurrentSubscription();
  }

  /// Gets the status of the latest subscription for a specific provider.
  static Future<ResponseWithHttpCode?> getStatusOfLatestSubscriptionForProvider(
      String? provider) {
    return platform.getStatusOfLatestSubscriptionForProvider(provider);
  }

  // ---- Push Tokens ----

  /// Gets the current push token data.
  static Future<TokenData?> getPushToken() {
    return platform.getPushToken();
  }

  /// Sets or clears a push token for the given provider.
  static Future<void> setPushToken(String provider, String? token) {
    return platform.setPushToken(provider, token);
  }

  /// Forces a token refresh.
  static Future<void> forcedTokenUpdate() {
    return platform.forcedTokenUpdate();
  }

  /// Deletes a device token for the given provider.
  static Future<void> deleteDeviceToken(String provider) {
    return platform.deleteDeviceToken(provider);
  }

  /// Changes the push provider priority list.
  static Future<void> changePushProviderPriorityList(
      List<String> priorityList) {
    return platform.changePushProviderPriorityList(priorityList);
  }

  // ---- Push Handling (Android) ----

  /// Forwards a push payload to the SDK (Android).
  static Future<void> takePush(Map<String, String> message) {
    return platform.takePush(message);
  }

  /// Checks if a push message is from Altcraft.
  static Future<bool> isAltcraftPush(Map<String, String> message) {
    return platform.isAltcraftPush(message);
  }

  // ---- Permissions (Android) ----

  /// Requests notification permission (Android).
  /// Returns true if granted, false if denied.
  static Future<bool> requestNotificationPermission() {
    return platform.requestNotificationPermission();
  }

  // ---- Push Events (Android) ----

  /// Reports push delivery (Android).
  static Future<void> deliveryEvent(
      Map<String, String>? message, String? messageUID) {
    return platform.deliveryEvent(message, messageUID);
  }

  /// Reports push open (Android).
  static Future<void> openEvent(
      Map<String, String>? message, String? messageUID) {
    return platform.openEvent(message, messageUID);
  }
}
