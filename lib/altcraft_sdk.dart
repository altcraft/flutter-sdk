/// Altcraft SDK for Flutter.
///
/// Provides push notification management, mobile events, profile fields,
/// and subscription handling for Android and iOS.
///
/// ```dart
/// import 'package:altcraft_sdk/altcraft_sdk.dart';
///
/// // Initialize
/// await AltcraftSDK.initialize(AltcraftConfig(
///   apiUrl: 'https://your-api.altcraft.com',
///   appInfo: const AppInfo(
///     appID: 'firebase-app-id',
///     appIID: 'firebase-instance-id',
///     appVer: '1.0.0',
///   ),
///   providerPriorityList: ['android-firebase'],
/// ));
///
/// // Subscribe to push
/// AltcraftSDK.pushSubscribe(sync: true);
///
/// // Listen to SDK events
/// AltcraftSDK.subscribeToEvents().listen((event) {
///   print('${event.function}: ${event.message}');
/// });
/// ```
library;

export 'src/altcraft_sdk_platform_interface.dart';
export 'src/altcraft_sdk_method_channel.dart';
export 'src/models/altcraft_config.dart';
export 'src/models/sdk_event.dart';
export 'src/models/token_data.dart';
export 'src/models/subscription.dart';
export 'src/models/category_data.dart';
export 'src/models/response_with_http_code.dart';
export 'src/models/utm.dart';
export 'src/exceptions/altcraft_exception.dart';
export 'src/action_field_builder.dart';

import 'dart:async';

import 'src/altcraft_sdk_platform_interface.dart';
import 'src/altcraft_sdk_method_channel.dart';
import 'src/models/altcraft_config.dart';
import 'src/models/sdk_event.dart';
import 'src/models/token_data.dart';
import 'src/models/response_with_http_code.dart';

/// Main entry point for the Altcraft SDK.
///
/// All SDK operations are accessed through this class's static methods.
/// The underlying platform implementation defaults to [MethodChannelAltcraftSdk]
/// but can be overridden for testing by setting [platform].
///
/// JWT and push token providers are registered natively (in Application.onCreate
/// on Android and AppDelegate on iOS) and are not exposed through the Dart API.
class AltcraftSDK {
  AltcraftSDK._();

  /// The current platform interface implementation.
  ///
  /// Can be overridden for testing with a mock implementation.
  static AltcraftSdkPlatformInterface platform = MethodChannelAltcraftSdk();

  // ---- Initialization ----

  /// Initializes the Altcraft SDK with the given configuration.
  static Future<void> initialize(AltcraftConfig config) {
    return platform.initialize(config);
  }

  // ---- Push Subscription ----

  /// Subscribes to push notifications.
  static void pushSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    platform.pushSubscribe(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// Suspends push subscription.
  static void pushSuspend({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    platform.pushSuspend(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// Unsubscribes from push notifications.
  static void pushUnSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    platform.pushUnSubscribe(
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

  // ---- SDK Events ----

  /// Subscribes to SDK events stream.
  ///
  /// Returns a stream of [SdkEvent] objects. Each call creates an independent stream.
  static Stream<SdkEvent> subscribeToEvents() {
    return platform.subscribeToEvents();
  }

  /// Unsubscribes from SDK events.
  ///
  /// Stops event delivery from the native SDK. Call [subscribeToEvents] to re-subscribe.
  static Future<void> unsubscribeFromEvents() {
    return platform.unsubscribeFromEvents();
  }

  // ---- Mobile Events ----

  /// Sends a mobile event to the Altcraft platform.
  static void mobileEvent({
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
    platform.mobileEvent(
      sid: sid,
      eventName: eventName,
      sendMessageId: sendMessageId,
      payload: payload,
      matching: matching,
      matchingType: matchingType,
      profileFields: profileFields,
      subscription: subscription,
      utm: utm,
    );
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

  // ---- State ----

  /// Clears all SDK state.
  static Future<void> clear() {
    return platform.clear();
  }

  // ---- Push Handling (Android) ----

  /// Forwards a push payload to the SDK (Android).
  static void takePush(Map<String, String> message) {
    platform.takePush(message);
  }

  // ---- Permissions (Android) ----

  /// Requests notification permission (Android).
  /// Returns true if granted, false if denied.
  static Future<bool> requestNotificationPermission() {
    return platform.requestNotificationPermission();
  }

  // ---- Push Events (Android) ----

  /// Reports push delivery (Android).
  static void deliveryEvent(Map<String, String>? message, String? messageUID) {
    platform.deliveryEvent(message, messageUID);
  }

  /// Reports push open (Android).
  static void openEvent(Map<String, String>? message, String? messageUID) {
    platform.openEvent(message, messageUID);
  }

  // ---- UserDefaults (iOS) ----

  /// Stores a value in native storage (UserDefaults on iOS, SharedPreferences on Android).
  static void setUserDefaultsValue(
      String? suiteName, String key, dynamic value) {
    platform.setUserDefaultsValue(suiteName, key, value);
  }

  // ---- Profile ----

  /// Updates profile fields on the server.
  static void updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) {
    platform.updateProfileFields(
      profileFields: profileFields,
      skipTriggers: skipTriggers,
    );
  }

  // ---- Token Management ----

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

  // ---- Push Identification ----

  /// Checks if a push message is from Altcraft.
  static Future<bool> isAltcraftPush(Map<String, String> message) {
    return platform.isAltcraftPush(message);
  }

  // ---- Session (Android) ----

  /// Unlocks initial operations in the current session (Android).
  static void unlockInitialOperationsInThisSession() {
    platform.unlockInitialOperationsInThisSession();
  }

  // ---- App Group (iOS) ----

  /// Sets the App Group for UserDefaults (iOS).
  static void setAppGroup(String? groupName) {
    platform.setAppGroup(groupName);
  }
}
