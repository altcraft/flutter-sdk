import 'models/subscription.dart';
import 'models/utm.dart';
import 'altcraft_target_method_channel.dart';
import 'altcraft_target_platform_interface.dart';
import 'module_events.dart';

/// Target module of the Altcraft SDK.
///
/// Provides target event sending with payload, matching, subscription, and
/// UTM data for Android and iOS.
///
/// ```dart
/// import 'package:altcraft_target/altcraft_target.dart';
///
/// await AltcraftTarget.sendTarget(sid: '...', eventName: 'purchase');
/// ```
///
/// The underlying platform implementation defaults to [MethodChannelAltcraftTarget]
/// but can be overridden for testing by setting [platform].
class AltcraftTarget {
  AltcraftTarget._();

  /// The current platform interface implementation.
  ///
  /// Can be overridden for testing with a mock implementation.
  static AltcraftTargetPlatformInterface _platform =
      MethodChannelAltcraftTarget();

  static AltcraftTargetPlatformInterface get platform => _platform;

  static set platform(AltcraftTargetPlatformInterface value) {
    _platform = value;
    AltcraftTargetPlatformInterface.instance = value;
  }

  /// Target module event messages emitted by the native SDK.
  static const TargetModuleEvents moduleEvents = targetModuleEvents;

  /// Sends a target event to the Altcraft platform.
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
    return platform.sendTarget(
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
}
