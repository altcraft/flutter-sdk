import 'package:flutter/foundation.dart';

/// Target module events.
///
/// Holds the messages emitted by the native SDK. Catalogs of both platforms
/// are merged: a name available on only one platform keeps that platform's
/// message and never matches events on the other platform.
final class TargetModuleEvents {
  const TargetModuleEvents._();

  /// Android event messages.
  static const Map<String, String> android = <String, String>{
    'partsIsNull': 'target request parts is null',
    'retryLimit': 'target request retry limit',
    'invalidPayload': 'invalid target payload: not all values are primitives',
    'requestDataIsNull': 'target request data is null',
    'requestSuccessful': 'successful target request: event/post',
    'requestFailed': 'failed target request: event/post',
  };

  /// iOS event messages.
  static const Map<String, String> ios = <String, String>{
    'mobileRequestDataIsNil': 'mobile event request data is nil',
    'mobileEventRequestSuccessful': 'successful request: event/post',
    'mobileEventRequestFailed': 'failed request: event/post',
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

  /// Message of the `partsIsNull` event.
  String get partsIsNull => values['partsIsNull']!;

  /// Message of the `retryLimit` event.
  String get retryLimit => values['retryLimit']!;

  /// Message of the `invalidPayload` event.
  String get invalidPayload => values['invalidPayload']!;

  /// Message of the `requestDataIsNull` event.
  String get requestDataIsNull => values['requestDataIsNull']!;

  /// Message of the `requestSuccessful` event.
  String get requestSuccessful => values['requestSuccessful']!;

  /// Message of the `requestFailed` event.
  String get requestFailed => values['requestFailed']!;

  /// Message of the `mobileRequestDataIsNil` event.
  String get mobileRequestDataIsNil => values['mobileRequestDataIsNil']!;

  /// Message of the `mobileEventRequestSuccessful` event.
  String get mobileEventRequestSuccessful =>
      values['mobileEventRequestSuccessful']!;

  /// Message of the `mobileEventRequestFailed` event.
  String get mobileEventRequestFailed => values['mobileEventRequestFailed']!;
}

/// Target module events resolved for the current platform.
const TargetModuleEvents targetModuleEvents = TargetModuleEvents._();
