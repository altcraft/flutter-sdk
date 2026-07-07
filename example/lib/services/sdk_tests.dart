import 'dart:async';
import 'dart:io';

import 'package:altcraft_sdk/altcraft_sdk.dart';
import 'package:altcraft_sdk_example/services/store.dart';

class SdkTests {
  static Future<void> initializationSDK(ConfigData config) async {
    // Resolve JWT (anon or reg)
    final jwtAnon = await Store.instance.getJwtAnon();
    final jwtReg = await Store.instance.getJwtReg();
    final authStatus = await Store.instance.getAuthStatus();
    final jwt = authStatus ? jwtReg : jwtAnon;

    // Set JWT via UserDefaults for iOS compatibility
    await AltcraftSDK.setUserDefaultsValue(kAppGroupSuite, kJwtKey, jwt);

    if (Platform.isIOS) {
      await AltcraftSDK.setAppGroup(kAppGroupSuite);
    }

    final defaultProvider = Platform.isIOS ? 'ios-apns' : 'android-firebase';
    final apiConfig = AltcraftConfig(
      apiUrl: config.apiUrl,
      rToken: config.effectiveRToken,
      appInfo: AppInfo(
        appID: 'firebase-app-id-${Platform.isIOS ? 'ios' : 'android'}',
        appIID: 'firebase-instance-id-${Platform.isIOS ? 'ios' : 'android'}',
        appVer: '1.0.0',
      ),
      providerPriorityList: config.providerPriorityList.isEmpty
          ? [defaultProvider]
          : config.providerPriorityList,
      enableLogging: true,
    );

    await AltcraftSDK.initialize(apiConfig);

    if (Platform.isAndroid) {
      await AltcraftSDK.requestNotificationPermission();
    }
  }

  static void doPushSubscribe() {
    final ss = _lastSubscribeSettings;
    unawaited(
      AltcraftSDK.pushSubscribe(
        sync: ss?.sync,
        replace: ss?.replace,
        skipTriggers: ss?.skipTriggers,
        customFields: ss?.customFields.cast<String, dynamic>(),
        profileFields: ss?.profileFields.cast<String, dynamic>(),
        cats: ss?.cats.map((c) => c.toJson()).toList(),
      ),
    );
  }

  static void doPushSuspend() {
    unawaited(AltcraftSDK.pushSuspend());
  }

  static void doPushUnSubscribe() {
    unawaited(AltcraftSDK.pushUnSubscribe());
  }

  static void doLogin() {
    unawaited(AltcraftSDK.pushSubscribe());
  }

  static void doLogout() {
    unawaited(AltcraftSDK.pushUnSubscribe());
  }

  static Future<Map<String, dynamic>?> doGetProfileStatus() async {
    final status = await AltcraftSDK.getStatusOfLatestSubscription();
    return status?.response;
  }

  static Future<void> doForcedTokenUpdate() async {
    await AltcraftSDK.forcedTokenUpdate();
  }

  static Future<void> doClear() async {
    await AltcraftSDK.clear();
  }

  static void doSendMobileEvent(String eventName) {
    unawaited(
      AltcraftSDK.mobileEvent(
        sid: kMobileEventSid,
        eventName: eventName,
      ),
    );
  }

  static void doUpdateProfile(Map<String, String>? fields) {
    if (fields == null || fields.isEmpty) return;
    unawaited(
      AltcraftSDK.updateProfileFields(
        profileFields: fields.cast<String, dynamic>(),
      ),
    );
  }

  static SubscribeSettings? _lastSubscribeSettings;

  static void updateSubscribeSettings(SubscribeSettings settings) {
    _lastSubscribeSettings = settings;
  }
}
