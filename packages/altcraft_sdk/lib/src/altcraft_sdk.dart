import 'dart:async';

import 'package:altcraft_inapp/altcraft_inapp.dart';
import 'package:altcraft_profile/altcraft_profile.dart';
import 'package:altcraft_push/altcraft_push.dart';
import 'package:altcraft_target/altcraft_target.dart';
import 'altcraft_sdk_method_channel.dart';
import 'altcraft_sdk_platform_interface.dart';

/// Main entry point for the Altcraft SDK.
///
/// All SDK operations are accessed through this class's static methods.
/// Initialization is handled by this package's native plugin, which applies
/// the core configuration together with the initialization options of the
/// connected modules. All other operations are delegated to the module
/// packages ([AltcraftCore], [AltcraftPush], [AltcraftInApp],
/// [AltcraftTarget], [AltcraftProfile]).
///
/// The JWT provider is registered through [AltcraftSDK.setJwtProvider]; the
/// callback is invoked by the native SDK over the core module's method
/// channel. Push token providers are registered natively (in
/// Application.onCreate on Android and AppDelegate on iOS).
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
///
/// For module-specific initialization options use [AltcraftCore.initialize]
/// with an [AltcraftConfigBuilder] and the module builder extensions:
///
/// ```dart
/// await AltcraftCore.initialize(
///   AltcraftConfigBuilder(apiUrl: 'https://your-api.altcraft.com')
///       .pushConfig(const PushConfig(providerPriority: ['android-firebase']))
///       .inAppConfig(const InAppConfig())
///       .build(),
/// );
/// ```
class AltcraftSDK {
  AltcraftSDK._();

  /// The current platform interface implementation.
  ///
  /// Can be overridden for testing with a mock implementation.
  static AltcraftSdkPlatformInterface _platform = MethodChannelAltcraftSdk();

  static AltcraftSdkPlatformInterface get platform => _platform;

  static set platform(AltcraftSdkPlatformInterface value) {
    _platform = value;
    AltcraftSdkPlatformInterface.instance = value;
  }

  // ---- Initialization ----

  /// Initializes the Altcraft SDK with the given configuration.
  ///
  /// For module-specific initialization options (push, In-App) prefer
  /// [AltcraftCore.initialize] with an [AltcraftConfigBuilder] and the module
  /// builder extensions, which apply configurations through the shared core
  /// plugin.
  static Future<void> initialize(AltcraftConfig config) {
    return platform.initialize(config);
  }

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
    return AltcraftPush.pushSubscribe(
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
    return AltcraftPush.pushSuspend(
      sync: sync,
      profileFields: profileFields,
      customFields: customFields,
      cats: cats,
      replace: replace,
      skipTriggers: skipTriggers,
    );
  }

  /// Subscribes to In-App notifications.
  static Future<void> inAppSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) {
    return AltcraftInApp.inAppSubscribe(
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
    return AltcraftInApp.inAppUnsubscribe(
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
    return AltcraftPush.pushUnSubscribe(
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
    return AltcraftPush.unSuspendPushSubscription();
  }

  // ---- Subscription Status ----

  /// Gets the status of the latest subscription.
  static Future<ResponseWithHttpCode?> getStatusOfLatestSubscription() {
    return AltcraftPush.getStatusOfLatestSubscription();
  }

  /// Gets the status of the current subscription.
  static Future<ResponseWithHttpCode?> getStatusForCurrentSubscription() {
    return AltcraftPush.getStatusForCurrentSubscription();
  }

  /// Gets the status of the latest subscription for a specific provider.
  static Future<ResponseWithHttpCode?> getStatusOfLatestSubscriptionForProvider(
      String? provider) {
    return AltcraftPush.getStatusOfLatestSubscriptionForProvider(provider);
  }

  // ---- SDK Events ----

  /// Subscribes to SDK events stream.
  ///
  /// Returns a broadcast stream of [SdkEvent] objects. Multiple listeners can
  /// subscribe to the same underlying native event source. Call
  /// [unsubscribeFromEvents] to stop all event delivery.
  static Stream<SdkEvent> subscribeToEvents() {
    return AltcraftCore.subscribeToEvents();
  }

  /// Unsubscribes from SDK events.
  ///
  /// Stops event delivery from the native SDK. Call [subscribeToEvents] to re-subscribe.
  static Future<void> unsubscribeFromEvents() {
    return AltcraftCore.unsubscribeFromEvents();
  }

  // ---- Mobile Events ----

  /// Sends a mobile event to the Altcraft platform.
  static Future<void> sendTarget({
    required String sid,
    required String eventName,
    String? sendMessageId,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? matching,
    String? matchingType,
    Map<String, dynamic>? profileFields,
    Subscription? subscription,
    UTM? utm,
  }) {
    return AltcraftTarget.sendTarget(
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
    return AltcraftPush.getPushToken();
  }

  /// Sets or clears a push token for the given provider.
  static Future<void> setPushToken(String provider, String? token) {
    return AltcraftPush.setPushToken(provider, token);
  }

  // ---- State ----

  /// Clears all SDK state.
  static Future<void> clear() {
    return AltcraftCore.clear();
  }

  // ---- Push Handling (Android) ----

  /// Forwards a push payload to the SDK (Android).
  static Future<void> takePush(Map<String, String> message) {
    return AltcraftPush.takePush(message);
  }

  // ---- Permissions (Android) ----

  /// Requests notification permission (Android).
  /// Returns true if granted, false if denied.
  static Future<bool> requestNotificationPermission() {
    return AltcraftPush.requestNotificationPermission();
  }

  // ---- Push Events (Android) ----

  /// Reports push delivery (Android).
  static Future<void> deliveryEvent(
      Map<String, String>? message, String? messageUID) {
    return AltcraftPush.deliveryEvent(message, messageUID);
  }

  /// Reports push open (Android).
  static Future<void> openEvent(
      Map<String, String>? message, String? messageUID) {
    return AltcraftPush.openEvent(message, messageUID);
  }

  // ---- UserDefaults (iOS) ----

  /// Stores a string value in native storage (UserDefaults on iOS, SharedPreferences on Android).
  ///
  /// On iOS, [suiteName] selects the App Group UserDefaults suite.
  /// On Android, [suiteName] is ignored.
  static Future<void> setUserDefaultsValue(
      String? suiteName, String key, String? value) {
    return AltcraftCore.setUserDefaultsValue(suiteName, key, value);
  }

  // ---- Profile ----

  /// Updates profile fields on the server.
  static Future<void> updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) {
    return AltcraftProfile.updateProfileFields(
      profileFields: profileFields,
      skipTriggers: skipTriggers,
    );
  }

  // ---- Token Management ----

  /// Forces a token refresh.
  static Future<void> forcedTokenUpdate() {
    return AltcraftPush.forcedTokenUpdate();
  }

  /// Deletes a device token for the given provider.
  static Future<void> deleteDeviceToken(String provider) {
    return AltcraftPush.deleteDeviceToken(provider);
  }

  /// Changes the push provider priority list.
  static Future<void> changePushProviderPriorityList(
      List<String> priorityList) {
    return AltcraftPush.changePushProviderPriorityList(priorityList);
  }

  // ---- Push Identification ----

  /// Checks if a push message is from Altcraft.
  static Future<bool> isAltcraftPush(Map<String, String> message) {
    return AltcraftPush.isAltcraftPush(message);
  }

  // ---- Session (Android) ----

  /// Unlocks initial operations in the current session (Android).
  static Future<void> unlockInitialOperationsInThisSession() {
    return AltcraftCore.unlockInitialOperationsInThisSession();
  }

  // ---- App Group (iOS) ----

  /// Sets the App Group for UserDefaults (iOS).
  static Future<void> setAppGroup(String? groupName) {
    return AltcraftCore.setAppGroup(groupName);
  }

  // ---- Authentication ----

  /// Registers a JWT provider that the native SDK calls when it needs a token.
  ///
  /// The [provider] callback is invoked over the core module's method channel
  /// whenever the native SDK requests the current JWT token.
  static Future<void> setJwtProvider(Future<String?> Function() provider) {
    return AltcraftCore.setJwtProvider(provider);
  }

  /// Starts SDK authentication.
  static Future<void> authenticate() {
    return AltcraftCore.authenticate();
  }

  /// Logs the user out.
  static Future<void> logOut() {
    return AltcraftCore.logOut();
  }

  /// Returns whether the user is authenticated.
  static Future<bool> isAuthenticated() {
    return AltcraftCore.isAuthenticated();
  }

  // ---- InApp ----

  /// Sets the current screen for In-App placement matching.
  static Future<void> setScreen(String screen) {
    return AltcraftInApp.setScreen(screen);
  }

  /// Fires an In-App trigger by name.
  static Future<void> trigger(String name) {
    return AltcraftInApp.trigger(name);
  }

  /// Requests available In-App placements from the server.
  static Future<void> getPlacements() {
    return AltcraftInApp.getPlacements();
  }

  /// Replaces the in-app view animation listener.
  ///
  /// See [AltcraftInApp.setAnimations] for the matching rules.
  static Future<void> setInAppAnimations(List<InAppAnimation> animations) {
    return AltcraftInApp.setAnimations(animations);
  }

  /// Provides access to in-app placements with JSON content.
  ///
  /// See [AltcraftInApp.jsonContent] for the handler semantics.
  static const JsonContentApi jsonContent = AltcraftInApp.jsonContent;
}
