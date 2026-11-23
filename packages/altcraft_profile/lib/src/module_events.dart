import 'package:flutter/foundation.dart';

/// Profile module events.
///
/// Holds the messages emitted by the native SDK. Catalogs of both platforms
/// are merged: a name available on only one platform keeps that platform's
/// message and never matches events on the other platform.
final class ProfileModuleEvents {
  const ProfileModuleEvents._();

  /// Android event messages.
  static const Map<String, String> android = <String, String>{
    'requestDataIsNull': 'profile update request data is null',
    'retryLimit': 'profile update retry limit',
    'requestSuccessful': 'successful request: profile/update',
    'requestFailed': 'failed request: profile/update',
  };

  /// iOS event messages.
  static const Map<String, String> ios = <String, String>{
    'profileUpdateRequestDataIsNil': 'profile update request data is nil',
    'profileUpdateRequestSuccessful': 'successful request: profile/update',
    'profileUpdateRequestFailed': 'failed request: profile/update',
  };

  /// Returns event messages resolved for [platform].
  static Map<String, String> valuesFor(TargetPlatform platform) =>
      Map<String, String>.unmodifiable(<String, String>{
        ...android,
        ...ios,
        ...(platform == TargetPlatform.iOS ? ios : android),
      });

  /// Event messages resolved for the current platform.
  static final Map<String, String> values = valuesFor(defaultTargetPlatform);

  /// Message of the `requestDataIsNull` event.
  String get requestDataIsNull => values['requestDataIsNull']!;

  /// Message of the `retryLimit` event.
  String get retryLimit => values['retryLimit']!;

  /// Message of the `requestSuccessful` event.
  String get requestSuccessful => values['requestSuccessful']!;

  /// Message of the `requestFailed` event.
  String get requestFailed => values['requestFailed']!;

  /// Message of the `profileUpdateRequestDataIsNil` event.
  String get profileUpdateRequestDataIsNil =>
      values['profileUpdateRequestDataIsNil']!;

  /// Message of the `profileUpdateRequestSuccessful` event.
  String get profileUpdateRequestSuccessful =>
      values['profileUpdateRequestSuccessful']!;

  /// Message of the `profileUpdateRequestFailed` event.
  String get profileUpdateRequestFailed =>
      values['profileUpdateRequestFailed']!;
}

/// Profile module events resolved for the current platform.
const ProfileModuleEvents profileModuleEvents = ProfileModuleEvents._();
