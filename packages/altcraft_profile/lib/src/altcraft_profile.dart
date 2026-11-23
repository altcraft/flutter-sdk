import 'altcraft_profile_method_channel.dart';
import 'altcraft_profile_platform_interface.dart';
import 'module_events.dart';

/// Profile module of the Altcraft SDK.
///
/// Provides profile field updates for Android and iOS.
///
/// ```dart
/// import 'package:altcraft_profile/altcraft_profile.dart';
///
/// await AltcraftProfile.updateProfileFields(profileFields: {'name': 'John'});
/// ```
///
/// The underlying platform implementation defaults to [MethodChannelAltcraftProfile]
/// but can be overridden for testing by setting [platform].
class AltcraftProfile {
  AltcraftProfile._();

  /// The current platform interface implementation.
  ///
  /// Can be overridden for testing with a mock implementation.
  static AltcraftProfilePlatformInterface _platform = MethodChannelAltcraftProfile();

  static AltcraftProfilePlatformInterface get platform => _platform;

  static set platform(AltcraftProfilePlatformInterface value) {
    _platform = value;
    AltcraftProfilePlatformInterface.instance = value;
  }

  /// Profile module event messages emitted by the native SDK.
  static const ProfileModuleEvents moduleEvents = profileModuleEvents;

  /// Updates profile fields on the server.
  static Future<void> updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) {
    return platform.updateProfileFields(
      profileFields: profileFields,
      skipTriggers: skipTriggers,
    );
  }
}
