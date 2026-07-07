import 'dart:async';

import 'package:flutter/services.dart';
import 'package:altcraft_sdk/src/altcraft_sdk_platform_interface.dart';
import 'package:altcraft_sdk/src/models/altcraft_config.dart';
import 'package:altcraft_sdk/src/models/sdk_event.dart';
import 'package:altcraft_sdk/src/models/token_data.dart';
import 'package:altcraft_sdk/src/models/response_with_http_code.dart';
import 'package:altcraft_sdk/src/exceptions/altcraft_exception.dart';

/// MethodChannel implementation of [AltcraftSdkPlatformInterface].
class MethodChannelAltcraftSdk extends AltcraftSdkPlatformInterface {
  /// Creates a new instance using [MethodChannel] for communication.
  MethodChannelAltcraftSdk() {
    AltcraftSdkPlatformInterface.instance = this;
  }

  final MethodChannel _channel = const MethodChannel('com.altcraft/sdk');
  final EventChannel _eventChannel = const EventChannel('com.altcraft/events');
  Stream<SdkEvent>? _eventStream;

  // ---- Initialization ----

  @override
  Future<void> initialize(AltcraftConfig config) async {
    try {
      await _channel.invokeMethod('initialize', config.toMap());
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'initialize failed');
    }
  }

  // ---- Push Subscription ----

  @override
  Future<void> pushSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('pushSubscribe', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats,
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'pushSubscribe failed');
    }
  }

  @override
  Future<void> pushSuspend({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('pushSuspend', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats,
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'pushSuspend failed');
    }
  }

  @override
  Future<void> pushUnSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('pushUnSubscribe', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats,
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'pushUnSubscribe failed');
    }
  }

  @override
  Future<ResponseWithHttpCode?> unSuspendPushSubscription() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('unSuspendPushSubscription');
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'unSuspendPushSubscription failed');
    }
  }

  // ---- Subscription Status ----

  @override
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscription() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getStatusOfLatestSubscription');
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'getStatusOfLatestSubscription failed');
    }
  }

  @override
  Future<ResponseWithHttpCode?> getStatusForCurrentSubscription() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getStatusForCurrentSubscription');
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'getStatusForCurrentSubscription failed');
    }
  }

  @override
  Future<ResponseWithHttpCode?> getStatusOfLatestSubscriptionForProvider(String? provider) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getStatusOfLatestSubscriptionForProvider', {
        'provider': provider,
      });
      if (result == null) return null;
      return ResponseWithHttpCode.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'getStatusOfLatestSubscriptionForProvider failed');
    }
  }

  // ---- SDK Events ----

  @override
  Stream<SdkEvent> subscribeToEvents() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .asyncMap<SdkEvent>((dynamic event) {
          try {
            if (event is Map) {
              return SdkEvent.fromMap(Map<dynamic, dynamic>.from(event));
            }
            return SdkEvent(
              function: '',
              message: 'Invalid event received: $event',
              type: 'error',
            );
          } catch (e) {
            return SdkEvent(
              function: '',
              message: 'Failed to parse event: $e',
              type: 'error',
            );
          }
        });
    return _eventStream!;
  }

  @override
  Future<void> unsubscribeFromEvents() async {
    try {
      await _channel.invokeMethod('unsubscribeFromEvents');
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'unsubscribeFromEvents failed');
    }
  }

  // ---- Mobile Events ----

  @override
  Future<void> mobileEvent({
    required String sid,
    required String eventName,
    String? sendMessageId,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? matching,
    String? matchingType,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? subscription,
    Map<String, dynamic>? utm,
  }) async {
    try {
      await _channel.invokeMethod('mobileEvent', {
        'sid': sid,
        'eventName': eventName,
        'sendMessageId': sendMessageId,
        'payload': payload,
        'matching': matching,
        'matchingType': matchingType,
        'profileFields': profileFields,
        'subscription': subscription,
        'utm': utm,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'mobileEvent failed');
    }
  }

  // ---- Push Tokens ----

  @override
  Future<TokenData?> getPushToken() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getPushToken');
      if (result == null) return null;
      return TokenData.fromMap(result);
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'getPushToken failed');
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
      throw AltcraftException(code: e.code, message: e.message ?? 'setPushToken failed');
    }
  }

  // ---- State ----

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod('clear');
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'clear failed');
    }
  }

  // ---- Push Handling (Android) ----

  @override
  Future<void> takePush(Map<String, String> message) async {
    try {
      await _channel.invokeMethod('takePush', message);
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'takePush failed');
    }
  }

  // ---- Permissions (Android) ----

  @override
  Future<bool> requestNotificationPermission() async {
    final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
    return result ?? false;
  }

  // ---- Push Events (Android) ----

  @override
  Future<void> deliveryEvent(Map<String, String>? message, String? messageUID) async {
    try {
      await _channel.invokeMethod('deliveryEvent', {
        'message': message,
        'messageUID': messageUID,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'deliveryEvent failed');
    }
  }

  @override
  Future<void> openEvent(Map<String, String>? message, String? messageUID) async {
    try {
      await _channel.invokeMethod('openEvent', {
        'message': message,
        'messageUID': messageUID,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'openEvent failed');
    }
  }

  // ---- UserDefaults (iOS) ----

  @override
  Future<void> setUserDefaultsValue(String? suiteName, String key, String? value) async {
    try {
      await _channel.invokeMethod('setUserDefaultsValue', {
        'suiteName': suiteName,
        'key': key,
        'value': value,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'setUserDefaultsValue failed');
    }
  }

  // ---- Profile ----

  @override
  Future<void> updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('updateProfileFields', {
        'profileFields': profileFields,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'updateProfileFields failed');
    }
  }

  // ---- Token Management ----

  @override
  Future<void> forcedTokenUpdate() async {
    try {
      await _channel.invokeMethod('forcedTokenUpdate');
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'forcedTokenUpdate failed');
    }
  }

  @override
  Future<void> deleteDeviceToken(String provider) async {
    try {
      await _channel.invokeMethod('deleteDeviceToken', {'provider': provider});
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'deleteDeviceToken failed');
    }
  }

  @override
  Future<void> changePushProviderPriorityList(List<String> priorityList) async {
    try {
      await _channel.invokeMethod('changePushProviderPriorityList', {'priorityList': priorityList});
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'changePushProviderPriorityList failed');
    }
  }

  // ---- Push Identification ----

  @override
  Future<bool> isAltcraftPush(Map<String, String> message) async {
    final result = await _channel.invokeMethod<bool>('isAltcraftPush', message);
    return result ?? false;
  }

  // ---- Session (Android) ----

  @override
  Future<void> unlockInitialOperationsInThisSession() async {
    try {
      await _channel.invokeMethod('unlockInitialOperationsInThisSession');
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'unlockInitialOperationsInThisSession failed');
    }
  }

  // ---- App Group (iOS) ----

  @override
  Future<void> setAppGroup(String? groupName) async {
    try {
      await _channel.invokeMethod('setAppGroup', {'groupName': groupName});
    } on PlatformException catch (e) {
      throw AltcraftException(code: e.code, message: e.message ?? 'setAppGroup failed');
    }
  }
}
