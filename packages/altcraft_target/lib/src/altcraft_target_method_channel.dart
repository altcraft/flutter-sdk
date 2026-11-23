import 'package:flutter/services.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'models/subscription.dart';
import 'models/utm.dart';
import 'altcraft_target_platform_interface.dart';

/// MethodChannel implementation of [AltcraftTargetPlatformInterface].
class MethodChannelAltcraftTarget extends AltcraftTargetPlatformInterface {
  final MethodChannel _channel = const MethodChannel(AltcraftChannels.target);

  /// Creates a new instance using [MethodChannel] for communication.
  MethodChannelAltcraftTarget() {
    AltcraftTargetPlatformInterface.instance = this;
  }

  @override
  Future<void> sendTarget({
    required String sid,
    required String eventName,
    String? sendMessageId,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? matching,
    String? matchingType,
    Map<String, dynamic>? profileFields,
    Subscription? subscription,
    UTM? utm,
  }) async {
    try {
      await _channel.invokeMethod('sendTarget', {
        'sid': sid,
        'eventName': eventName,
        'sendMessageId': sendMessageId,
        'payload': payload,
        'matching': matching,
        'matchingType': matchingType,
        'profileFields': profileFields,
        'subscription': subscription?.toMap(),
        'utm': utm?.toMap(),
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'sendTarget failed');
    }
  }
}
