import 'package:flutter/foundation.dart';

/// In-App module events.
///
/// Holds the messages emitted by the native SDK. Catalogs of both platforms
/// are merged: a name available on only one platform keeps that platform's
/// message and never matches events on the other platform.
final class InAppModuleEvents {
  const InAppModuleEvents._();

  /// Android event messages.
  static const Map<String, String> android = <String, String>{
    'maxPlacementsInvalid':
        'Invalid in-app configuration: maxPlacements must be >= 1',
    'requestIntervalInvalid':
        'Invalid in-app configuration: placementsRequestInterval must be >= 15 minutes',
    'subscribeRetryLimit': 'in-app subscribe retry limit',
    'subscribeRequestDataIsNull': 'in-app subscribe request data is null',
    'subscribeRequestSuccessful': 'successful request: inapp/subscribe',
    'subscribeRequestFailed': 'failed request: inapp/subscribe',
    'unsubscribeRequestSuccessful': 'successful request: inapp/unsubscribe',
    'unsubscribeRequestFailed': 'failed request: inapp/unsubscribe',
    'invalidCustomFields':
        'invalid custom fields: not all values are primitives',
    'statusRequestDataIsNull': 'in-app status request data is null',
    'statusRequestSuccessful': 'successful request: inapp/status',
    'statusRequestFailed': 'failed request: inapp/status',
    'eventRetryLimit': 'in-app event retry limit',
    'eventRequestDataIsNull': 'in-app event request data is null',
    'smidIsNull': 'send message ID is null',
    'eventRequestSuccessful': 'successful request: inapp/event',
    'eventRequestFailed': 'failed request: inapp/event',
    'placementsRequestDataIsNull': 'in-app placements request data is null',
    'placementsRequestSuccessful': 'successful request: inapp/placements',
    'placementsRequestFailed': 'failed request: inapp/placements',
    'placementsLimitExceeded': 'in-app placements limit exceeded',
    'inAppCanShowFailed':
        'in-app was not shown because a display policy check failed:',
    'invalidStaticField': 'invalid in-app static field',
    'inAppStaticErrorLoad':
        'error loading in-app notification static resources',
    'inAppContentErrorLoad': 'error loading in-app notification content',
  };

  /// iOS event messages.
  static const Map<String, String> ios = <String, String>{
    'errorInAppImageLoad': 'failed to load in-app image',
    'invalidStaticField': 'invalid in-app static field',
    'smidIsNil':
        'smid in the in-app data is null, it is impossible to send a in-app event to the server.',
    'acidIsNil':
        'acid in the in-app data is null, it is impossible to send a in-app event to the server.',
    'inAppStatusRequestDataIsNil': 'in-app status request data is nil',
    'inAppEventRequestDataIsNil': 'in-app event request data is nil',
    'subscribeRequestDataIsNil': 'in-app subscribe request data is nil',
    'invalidSubRequestData': 'invalid in-app subscribe request data',
    'inAppUnsubscribeRequestSuccessful':
        'successful request: inapp/unsubscribe',
    'inAppSubscribeRequestSuccessful': 'successful request: inapp/subscribe',
    'inAppStatusRequestSuccessful': 'successful request: inapp/status',
    'inAppEventRequestSuccessful': 'successful request: inapp/event',
    'inAppPlacementsRequestSuccessful': 'successful request: inapp/placements',
    'inAppUnsubscribeRequestFailed': 'failed request: inapp/unsubscribe',
    'inAppPlacementsRequestFailed': 'failed request: inapp/placements',
    'inAppSubscribeRequestFailed': 'failed request: inapp/subscribe',
    'inAppStatusRequestFailed': 'failed request: inapp/status',
    'inAppEventRequestFailed': 'failed request: inapp/event',
    'inAppStaticErrorLoad':
        'error loading in-app notification static resources',
    'inAppContentErrorLoad': 'error loading in-app notification content',
    'maxPlacementsInvalid':
        'Invalid in-app configuration: maxPlacements must be >= 1',
    'requestIntervalInvalid':
        'Invalid in-app configuration: placementsRequestInterval must be > 0',
    'placementsLimitExceeded': 'in-app placements limit exceeded',
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

  /// Message of the `maxPlacementsInvalid` event.
  String get maxPlacementsInvalid => values['maxPlacementsInvalid']!;

  /// Message of the `requestIntervalInvalid` event.
  String get requestIntervalInvalid => values['requestIntervalInvalid']!;

  /// Message of the `subscribeRetryLimit` event.
  String get subscribeRetryLimit => values['subscribeRetryLimit']!;

  /// Message of the `subscribeRequestDataIsNull` event.
  String get subscribeRequestDataIsNull =>
      values['subscribeRequestDataIsNull']!;

  /// Message of the `subscribeRequestSuccessful` event.
  String get subscribeRequestSuccessful =>
      values['subscribeRequestSuccessful']!;

  /// Message of the `subscribeRequestFailed` event.
  String get subscribeRequestFailed => values['subscribeRequestFailed']!;

  /// Message of the `unsubscribeRequestSuccessful` event.
  String get unsubscribeRequestSuccessful =>
      values['unsubscribeRequestSuccessful']!;

  /// Message of the `unsubscribeRequestFailed` event.
  String get unsubscribeRequestFailed => values['unsubscribeRequestFailed']!;

  /// Message of the `invalidCustomFields` event.
  String get invalidCustomFields => values['invalidCustomFields']!;

  /// Message of the `statusRequestDataIsNull` event.
  String get statusRequestDataIsNull => values['statusRequestDataIsNull']!;

  /// Message of the `statusRequestSuccessful` event.
  String get statusRequestSuccessful => values['statusRequestSuccessful']!;

  /// Message of the `statusRequestFailed` event.
  String get statusRequestFailed => values['statusRequestFailed']!;

  /// Message of the `eventRetryLimit` event.
  String get eventRetryLimit => values['eventRetryLimit']!;

  /// Message of the `eventRequestDataIsNull` event.
  String get eventRequestDataIsNull => values['eventRequestDataIsNull']!;

  /// Message of the `smidIsNull` event.
  String get smidIsNull => values['smidIsNull']!;

  /// Message of the `eventRequestSuccessful` event.
  String get eventRequestSuccessful => values['eventRequestSuccessful']!;

  /// Message of the `eventRequestFailed` event.
  String get eventRequestFailed => values['eventRequestFailed']!;

  /// Message of the `placementsRequestDataIsNull` event.
  String get placementsRequestDataIsNull =>
      values['placementsRequestDataIsNull']!;

  /// Message of the `placementsRequestSuccessful` event.
  String get placementsRequestSuccessful =>
      values['placementsRequestSuccessful']!;

  /// Message of the `placementsRequestFailed` event.
  String get placementsRequestFailed => values['placementsRequestFailed']!;

  /// Message of the `placementsLimitExceeded` event.
  String get placementsLimitExceeded => values['placementsLimitExceeded']!;

  /// Message of the `inAppCanShowFailed` event.
  String get inAppCanShowFailed => values['inAppCanShowFailed']!;

  /// Message of the `invalidStaticField` event.
  String get invalidStaticField => values['invalidStaticField']!;

  /// Message of the `inAppStaticErrorLoad` event.
  String get inAppStaticErrorLoad => values['inAppStaticErrorLoad']!;

  /// Message of the `inAppContentErrorLoad` event.
  String get inAppContentErrorLoad => values['inAppContentErrorLoad']!;

  /// Message of the `errorInAppImageLoad` event.
  String get errorInAppImageLoad => values['errorInAppImageLoad']!;

  /// Message of the `smidIsNil` event.
  String get smidIsNil => values['smidIsNil']!;

  /// Message of the `acidIsNil` event.
  String get acidIsNil => values['acidIsNil']!;

  /// Message of the `inAppStatusRequestDataIsNil` event.
  String get inAppStatusRequestDataIsNil =>
      values['inAppStatusRequestDataIsNil']!;

  /// Message of the `inAppEventRequestDataIsNil` event.
  String get inAppEventRequestDataIsNil =>
      values['inAppEventRequestDataIsNil']!;

  /// Message of the `subscribeRequestDataIsNil` event.
  String get subscribeRequestDataIsNil => values['subscribeRequestDataIsNil']!;

  /// Message of the `invalidSubRequestData` event.
  String get invalidSubRequestData => values['invalidSubRequestData']!;

  /// Message of the `inAppUnsubscribeRequestSuccessful` event.
  String get inAppUnsubscribeRequestSuccessful =>
      values['inAppUnsubscribeRequestSuccessful']!;

  /// Message of the `inAppSubscribeRequestSuccessful` event.
  String get inAppSubscribeRequestSuccessful =>
      values['inAppSubscribeRequestSuccessful']!;

  /// Message of the `inAppStatusRequestSuccessful` event.
  String get inAppStatusRequestSuccessful =>
      values['inAppStatusRequestSuccessful']!;

  /// Message of the `inAppEventRequestSuccessful` event.
  String get inAppEventRequestSuccessful =>
      values['inAppEventRequestSuccessful']!;

  /// Message of the `inAppPlacementsRequestSuccessful` event.
  String get inAppPlacementsRequestSuccessful =>
      values['inAppPlacementsRequestSuccessful']!;

  /// Message of the `inAppUnsubscribeRequestFailed` event.
  String get inAppUnsubscribeRequestFailed =>
      values['inAppUnsubscribeRequestFailed']!;

  /// Message of the `inAppPlacementsRequestFailed` event.
  String get inAppPlacementsRequestFailed =>
      values['inAppPlacementsRequestFailed']!;

  /// Message of the `inAppSubscribeRequestFailed` event.
  String get inAppSubscribeRequestFailed =>
      values['inAppSubscribeRequestFailed']!;

  /// Message of the `inAppStatusRequestFailed` event.
  String get inAppStatusRequestFailed => values['inAppStatusRequestFailed']!;

  /// Message of the `inAppEventRequestFailed` event.
  String get inAppEventRequestFailed => values['inAppEventRequestFailed']!;
}

/// In-App module events resolved for the current platform.
const InAppModuleEvents inAppModuleEvents = InAppModuleEvents._();
