import 'dart:async';
import 'dart:io';

import 'package:altcraft_push/altcraft_push.dart';
import 'package:altcraft_inapp/altcraft_inapp.dart';
import 'package:altcraft_target/altcraft_target.dart';
import 'package:altcraft_profile/altcraft_profile.dart';
import 'package:altcraft_sdk_example/services/app_state.dart';
import 'package:altcraft_sdk_example/services/store.dart';

class SdkTests {
  static Future<void> initializationSDK(ConfigData config) async {
    final apiUrl = config.apiUrl;
    if (apiUrl == null || apiUrl.trim().isEmpty) {
      return;
    }

    // Resolve JWT (anon or reg)
    final jwtAnon = await Store.instance.getJwtAnon();
    final jwtReg = await Store.instance.getJwtReg();
    final externalAuth = await Store.instance.getExternalAuthStatus();
    final jwt = externalAuth ? jwtReg : jwtAnon;

    // Set JWT via UserDefaults for iOS compatibility
    await AltcraftCore.setUserDefaultsValue(kAppGroupSuite, kJwtKey, jwt);

    if (Platform.isIOS) {
      await AltcraftCore.setAppGroup(kAppGroupSuite);
    }

    // Modular initialization: core parameters plus module configurations
    // contributed through builder extensions. The push and In-App packages
    // are imported, so their `pushConfig`/`inAppConfig` extensions are
    // available and applied by the core module during initialization.
    final apiConfig = AltcraftConfigBuilder(
      apiUrl: apiUrl,
      rToken: config.effectiveRToken,
      appInfo: const AppInfo(
        appID: kAppId,
        appIID: kAppIid,
        appVer: kAppVer,
      ),
      enableLogging: true,
    )
        .pushConfig(PushConfig(
          providerPriority: config.providerPriorityList,
        ))
        .inAppConfig(const InAppConfig())
        .build();

    await AltcraftCore.initialize(apiConfig);

    // In-App view animation: every campaign slides up and fades in.
    // A spec without a companyId acts as the fallback for all campaigns.
    await AltcraftInApp.setAnimations([
      const InAppAnimation(
        alphaFrom: 0,
        alphaTo: 1,
        translateYFrom: 80,
        translateYTo: 0,
        scaleXFrom: 0.96,
        scaleYFrom: 0.96,
        scaleXTo: 1,
        scaleYTo: 1,
        easing: InAppAnimationEasing.easeOut,
      ),
    ]);

    // JSON-content campaigns are not displayed: the raw JSON is delivered to
    // the subscribed handler and shown on the Logs screen.
    await AltcraftInApp.jsonContent.subscribe(
      AppState.instance.addJsonContent,
    );

    // The saved push provider priority is applied at initialization through
    // the `pushConfig` builder extension above.

    if (Platform.isAndroid) {
      await AltcraftCore.setJwtProvider(() async {
        final auth = await Store.instance.getExternalAuthStatus();
        return auth
            ? await Store.instance.getJwtReg()
            : await Store.instance.getJwtAnon();
      });
      await AltcraftPush.requestNotificationPermission();
      await AltcraftInApp.setScreen('home');
      await AppState.instance.syncAuthFromSdk();
    }

    final savedStatus = await Store.instance.getAppStatus();
    if (savedStatus == kUnsubscribed) {
      unawaited(AltcraftPush.getStatusForCurrentSubscription());
    }
  }

  /// Mirrors SDKFunctions.Subscribe.subscribe
  static Future<void> doPushSubscribe() async {
    final ss = await Store.instance.getSubscribeSettings();
    await AltcraftPush.pushSubscribe(
      sync: ss.sync != false,
      replace: ss.replace == true,
      skipTriggers: ss.skipTriggers == true,
      customFields: ss.customFields.cast<String, dynamic>(),
      profileFields: ss.profileFields.cast<String, dynamic>(),
      cats: ss.cats,
    );
  }

  /// Mirrors SDKFunctions.Subscribe.unSubscribe
  static Future<void> doPushUnSubscribe() async {
    final ss = await Store.instance.getSubscribeSettings();
    await AltcraftPush.pushUnSubscribe(
      sync: ss.sync != false,
      replace: ss.replace == true,
      skipTriggers: ss.skipTriggers == true,
      customFields: ss.customFields.cast<String, dynamic>(),
      profileFields: ss.profileFields.cast<String, dynamic>(),
    );
  }

  static Future<void> doInAppSubscribe() async {
    final ss = await Store.instance.getSubscribeSettings();
    await AltcraftInApp.inAppSubscribe(
      sync: ss.sync != false,
      replace: ss.replace == true,
      skipTriggers: ss.skipTriggers == true,
      customFields: ss.customFields.cast<String, dynamic>(),
      profileFields: ss.profileFields.cast<String, dynamic>(),
      cats: ss.cats,
    );
  }

  static Future<void> doInAppUnsubscribe() async {
    final ss = await Store.instance.getSubscribeSettings();
    await AltcraftInApp.inAppUnsubscribe(
      sync: ss.sync != false,
      replace: ss.replace == true,
      skipTriggers: ss.skipTriggers == true,
      customFields: ss.customFields.cast<String, dynamic>(),
      profileFields: ss.profileFields.cast<String, dynamic>(),
    );
  }

  /// Mirrors SDKFunctions.Login.unSuspend flow.
  static Future<void> doLogin() async {
    await _unSuspend(true);
  }

  static Future<void> doLogout() async {
    await _unSuspend(false);
  }

  static Future<void> _unSuspend(bool logIn) async {
    final ss = await Store.instance.getSubscribeSettings();
    await Store.instance.saveExternalAuthStatus(logIn);

    final response = await AltcraftPush.unSuspendPushSubscription();
    final profile = response?.response?['profile'];
    final subscription = profile is Map ? profile['subscription'] : null;
    if (response?.httpCode == 200 && subscription == null) {
      await AltcraftPush.pushSubscribe(
        sync: true,
        replace: ss.replace == false,
        skipTriggers: ss.skipTriggers == false,
        customFields: ss.customFields.cast<String, dynamic>(),
        profileFields: ss.profileFields.cast<String, dynamic>(),
      );
    }
  }

  /// Mirrors SDKFunctions.updateProvider
  static Future<void> doUpdateProvider(List<String> providerList) async {
    await AltcraftPush.changePushProviderPriorityList(providerList);

    final currentConfig = await Store.instance.getConfig();
    await Store.instance.saveConfig(ConfigData(
      apiUrl: currentConfig.apiUrl,
      rToken: currentConfig.rToken,
      providerPriorityList: providerList,
    ));
    await AppStateHolder.updateTokenUi();
  }

  static Future<Map<String, dynamic>?> doGetProfileStatus() async {
    final response = await AltcraftPush.getStatusForCurrentSubscription();
    if (response == null) return null;
    return {
      'http_code': response.httpCode,
      'response': response.response,
    };
  }

  static Future<void> doForcedTokenUpdate() async {
    await AltcraftPush.forcedTokenUpdate();
  }

  static Future<void> doClear() async {
    await AltcraftCore.clear();
  }

  static Future<void> doSendMobileEvent(String sid, String name) async {
    await AltcraftTarget.sendTarget(sid: sid, eventName: name);
  }

  /// Mirrors SDKFunctions.updateProfileFields
  static Future<void> doUpdateProfileFields(
    Map<String, dynamic> profileFields,
  ) async {
    await AltcraftProfile.updateProfileFields(profileFields: profileFields);
  }
}

/// Indirection so SdkTests can refresh token UI without a widget context.
class AppStateHolder {
  static Future<void> Function()? _updateTokenUi;

  static void bind(Future<void> Function() updateTokenUi) {
    _updateTokenUi = updateTokenUi;
  }

  static Future<void> updateTokenUi() async {
    await _updateTokenUi?.call();
  }
}
