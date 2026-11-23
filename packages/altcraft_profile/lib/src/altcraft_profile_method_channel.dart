import 'package:flutter/services.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'altcraft_profile_platform_interface.dart';

/// MethodChannel implementation of [AltcraftProfilePlatformInterface].
class MethodChannelAltcraftProfile extends AltcraftProfilePlatformInterface {
  final MethodChannel _channel = const MethodChannel(AltcraftChannels.profile);

  /// Creates a new instance using [MethodChannel] for communication.
  MethodChannelAltcraftProfile() {
    AltcraftProfilePlatformInterface.instance = this;
  }

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
      throw AltcraftException(
          code: e.code, message: e.message ?? 'updateProfileFields failed');
    }
  }
}
