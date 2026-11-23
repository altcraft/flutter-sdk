import 'package:flutter/services.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'models/token_data.dart';
import 'altcraft_push_platform_interface.dart';

/// MethodChannel implementation of [AltcraftPushPlatformInterface].
class MethodChannelAltcraftPush extends AltcraftPushPlatformInterface {
  final MethodChannel _channel = const MethodChannel(AltcraftChannels.push);

  /// Creates a new instance using [MethodChannel] for communication.
  MethodChannelAltcraftPush() {
    AltcraftPushPlatformInterface.instance = this;
  }

  // ---- Push Subscription ----

  @override
  Future<void> pushSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('pushSubscribe', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats?.map((c) => c.toMap()).toList(),
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'pushSubscribe failed');
    }
  }

  @override
  Future<void> pushSuspend({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('pushSuspend', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats?.map((c) => c.toMap()).toList(),
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'pushSuspend failed');
    }
  }

  @override
  Future<void> pushUnSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('pushUnSubscribe', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats?.map((c) => c.toMap()).toList(),
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'pushUnSubscribe failed');
    }
  }

  @override
  Future<ResponseWithHttpCode?> unSuspendPushSubscription() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('unSuspendPushSubscription');
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code,
          message: e.message ?? 'unSuspendPushSubscription failed');
    }
  }

  // ---- Subscription Status ----

  @override
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscription() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getStatusOfLatestSubscription');
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code,
          message: e.message ?? 'getStatusOfLatestSubscription failed');
    }
  }

  @override
  Future<ResponseWithHttpCode?> getStatusForCurrentSubscription() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getStatusForCurrentSubscription');
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code,
          message: e.message ?? 'getStatusForCurrentSubscription failed');
    }
  }

  @override
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscriptionForProvider(
      String? provider) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
          'getStatusOfLatestSubscriptionForProvider', {
        'provider': provider,
      });
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code,
          message:
              e.message ?? 'getStatusOfLatestSubscriptionForProvider failed');
    }
  }

  // ---- Push Tokens ----

  @override
  Future<TokenData?> getPushToken() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getPushToken');
      if (result == null) return null;
      return TokenData.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'getPushToken failed');
    }
  }

  @override
  Future<void> setPushToken(String provider, String? token) async {
    try {
      await _channel.invokeMethod('setPushToken', {
        'provider': provider,
        'token': token,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'setPushToken failed');
    }
  }

  @override
  Future<void> forcedTokenUpdate() async {
    try {
      await _channel.invokeMethod('forcedTokenUpdate');
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'forcedTokenUpdate failed');
    }
  }

  @override
  Future<void> deleteDeviceToken(String provider) async {
    try {
      await _channel.invokeMethod('deleteDeviceToken', {'provider': provider});
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'deleteDeviceToken failed');
    }
  }

  @override
  Future<void> changePushProviderPriorityList(List<String> priorityList) async {
    try {
      await _channel.invokeMethod(
          'changePushProviderPriorityList', {'priorityList': priorityList});
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code,
          message: e.message ?? 'changePushProviderPriorityList failed');
    }
  }

  // ---- Push Handling (Android) ----

  @override
  Future<void> takePush(Map<String, String> message) async {
    try {
      await _channel.invokeMethod('takePush', message);
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'takePush failed');
    }
  }

  @override
  Future<bool> isAltcraftPush(Map<String, String> message) async {
    final result = await _channel.invokeMethod<bool>('isAltcraftPush', message);
    return result ?? false;
  }

  // ---- Permissions (Android) ----

  @override
  Future<bool> requestNotificationPermission() async {
    final result =
        await _channel.invokeMethod<bool>('requestNotificationPermission');
    return result ?? false;
  }

  // ---- Push Events (Android) ----

  @override
  Future<void> deliveryEvent(
      Map<String, String>? message, String? messageUID) async {
    try {
      await _channel.invokeMethod('deliveryEvent', {
        'message': message,
        'messageUID': messageUID,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'deliveryEvent failed');
    }
  }

  @override
  Future<void> openEvent(
      Map<String, String>? message, String? messageUID) async {
    try {
      await _channel.invokeMethod('openEvent', {
        'message': message,
        'messageUID': messageUID,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'openEvent failed');
    }
  }
}
