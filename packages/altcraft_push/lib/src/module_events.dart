import 'package:flutter/foundation.dart';

/// Push module events.
///
/// Holds the messages emitted by the native SDK. Catalogs of both platforms
/// are merged: a name available on only one platform keeps that platform's
/// message and never matches events on the other platform.
final class PushModuleEvents {
  const PushModuleEvents._();

  /// Android event messages.
  static const Map<String, String> android = <String, String>{
    'invalidProvider':
        'Invalid push configuration: unsupported push provider. Available providers: android-firebase, android-huawei, android-rustore.',
    'configIsNull': 'push configuration is null',
    'invalidCustomFields':
        'invalid custom fields: not all values are primitives',
    'eventRetryLimit': 'push event retry limit',
    'eventRequestDataIsNull': 'push event request data is null',
    'eventRequestSuccessful': 'successful request: event/push',
    'eventRequestFailed': 'failed request: event/push',
    'pushUidIsNull': 'push uid is null',
    'subscribeRetryLimit': 'push subscribe retry limit',
    'subscribeRequestDataIsNull': 'push subscribe request data is null',
    'subscribeRequestSuccessful': 'successful request: push/subscribe',
    'subscribeRequestFailed': 'failed request: push/subscribe',
    'suspendRequestSuccessful': 'successful request: push/suspend',
    'suspendRequestFailed': 'failed request: push/suspend',
    'unsubscribeRequestSuccessful': 'successful request: push/unsubscribe',
    'unsubscribeRequestFailed': 'failed request: push/unsubscribe',
    'tokenUpdateRequestDataIsNull': 'token update request data is null',
    'tokenUpdateRequestSuccessful': 'successful request: push/update',
    'tokenUpdateRequestFailed': 'failed request: push/update',
    'pushTokenIsNull': 'push token is null',
    'notUpdated': 'push token not updated',
    'pushProviderSet': 'push provider set -',
    'invalidPushProvider':
        'Invalid push provider. Available providers: android-firebase, android-huawei, android-rustore.',
    'statusRequestDataIsNull': 'subscription status request data is null',
    'statusRequestSuccess': 'successful request: push/status',
    'statusRequestFailed': 'failed request: push/status',
    'unSuspendRequestDataIsNull': 'unsuspend request data is null',
    'unSuspendRequestSuccessful': 'successful request: push/unsuspend',
    'unSuspendRequestFailed': 'failed request: push/unsuspend',
    'pushDataIsNull': 'push data is null',
    'notificationErr': 'notification error',
    'channelNotCreated': 'notification channel not created',
    'pushPermissionDenied': 'notification permission denied',
    'pushIsPosted': 'push notification is posted',
    'acPush': 'Altcraft push notification received',
    'notAcPush': 'received a notification unrelated to the Altcraft Platform',
    'duplicatePushMessage':
        'duplicate push message: processing and display skipped',
    'receiverRedefined': 'push receiver redefined',
    'errorImgLoad': 'error loading push image',
    'successImgLoad': 'push image loaded successfully',
  };

  /// iOS event messages.
  static const Map<String, String> ios = <String, String>{
    'pushProviderSet': 'push provider set: ',
    'pushReceive': 'received Altcraft push notification.',
    'pushIsPosted': 'push is posted.',
    'duplicatePushMessage': 'duplicate push message, uid: ',
    'pushTokenUpdateAwait': 'waiting for push token update to complete',
    'apnsIsNotUpdated':
        'forcing a push token update is not possible: the operation is not supported for APNs.',
    'errorHandleUserInfo': 'invalid userInfo format',
    'uidIsNil':
        'uid in the push data is null, it is impossible to send a push event to the server.',
    'errorMediaDownload': 'could not download image data from URL.',
    'errorMediaKeyMissing':
        '\'media\' key is missing or URL string is invalid.',
    'errorButtonsKeyMissing': '\'buttons\' key is missing or is invalid.',
    'invalidButtonIdentifier': 'invalid button identifier. See event value',
    'outOfRangeForIdentifier': 'out of range for identifier. See event value',
    'unknownButtonIdentifier': 'unknown button identifier. See event value',
    'invalidPushProviders':
        'invalid provider. Available - ios-apns, ios-firebase, ios-huawei.',
    'invalidPushProvider': 'invalid provider.',
    'pushTokenIsNil': 'current push token is nil',
    'subscribeRequestDataIsNil': 'subscribe request data is nil',
    'updateRequestDataIsNil': 'update request data is nil',
    'pushEventRequestDataIsNil': 'push event request data is nil',
    'unsuspendRequestDataIsNil': 'unsuspend request data is nil',
    'pushStatusRequestDataIsNil': 'push status request data is nil',
    'invalidSubRequestData': 'invalid push subscribe request data',
    'invalidPushEventRequestData': 'invalid push event request data',
    'pushConfigurationSaveFailed':
        'failed to save the push configuration to the local database',
    'pushConfigurationClearFailed':
        'failed to clear the push configuration from the local database',
    'pushUnsubscribeRequestSuccessful': 'successful request: push/unsubscribe',
    'pushSubscribeRequestSuccessful': 'successful request: push/subscribe',
    'pushSuspendRequestSuccessful': 'successful request: push/suspend',
    'pushStatusRequestSuccessful': 'successful request: push/status',
    'tokenUpdateRequestSuccessful': 'successful request: push/update',
    'pushEventRequestSuccessful': 'successful request: event/push',
    'unsuspendRequestSuccessful': 'successful request: push/unsuspend',
    'pushUnsubscribeRequestFailed': 'failed request: push/unsubscribe',
    'pushSubscribeRequestFailed': 'failed request: push/subscribe',
    'pushSuspendRequestFailed': 'failed request: push/suspend',
    'pushStatusRequestFailed': 'failed request: push/status',
    'tokenUpdateRequestFailed': 'failed request: push/update',
    'pushEventRequestFailed': 'failed request: event/push',
    'unsuspendRequestFailed': 'failed request: push/unsuspend',
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

  /// Message of the `invalidProvider` event.
  String get invalidProvider => values['invalidProvider']!;

  /// Message of the `configIsNull` event.
  String get configIsNull => values['configIsNull']!;

  /// Message of the `invalidCustomFields` event.
  String get invalidCustomFields => values['invalidCustomFields']!;

  /// Message of the `eventRetryLimit` event.
  String get eventRetryLimit => values['eventRetryLimit']!;

  /// Message of the `eventRequestDataIsNull` event.
  String get eventRequestDataIsNull => values['eventRequestDataIsNull']!;

  /// Message of the `eventRequestSuccessful` event.
  String get eventRequestSuccessful => values['eventRequestSuccessful']!;

  /// Message of the `eventRequestFailed` event.
  String get eventRequestFailed => values['eventRequestFailed']!;

  /// Message of the `pushUidIsNull` event.
  String get pushUidIsNull => values['pushUidIsNull']!;

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

  /// Message of the `suspendRequestSuccessful` event.
  String get suspendRequestSuccessful => values['suspendRequestSuccessful']!;

  /// Message of the `suspendRequestFailed` event.
  String get suspendRequestFailed => values['suspendRequestFailed']!;

  /// Message of the `unsubscribeRequestSuccessful` event.
  String get unsubscribeRequestSuccessful =>
      values['unsubscribeRequestSuccessful']!;

  /// Message of the `unsubscribeRequestFailed` event.
  String get unsubscribeRequestFailed => values['unsubscribeRequestFailed']!;

  /// Message of the `tokenUpdateRequestDataIsNull` event.
  String get tokenUpdateRequestDataIsNull =>
      values['tokenUpdateRequestDataIsNull']!;

  /// Message of the `tokenUpdateRequestSuccessful` event.
  String get tokenUpdateRequestSuccessful =>
      values['tokenUpdateRequestSuccessful']!;

  /// Message of the `tokenUpdateRequestFailed` event.
  String get tokenUpdateRequestFailed => values['tokenUpdateRequestFailed']!;

  /// Message of the `pushTokenIsNull` event.
  String get pushTokenIsNull => values['pushTokenIsNull']!;

  /// Message of the `notUpdated` event.
  String get notUpdated => values['notUpdated']!;

  /// Message of the `pushProviderSet` event.
  String get pushProviderSet => values['pushProviderSet']!;

  /// Message of the `invalidPushProvider` event.
  String get invalidPushProvider => values['invalidPushProvider']!;

  /// Message of the `statusRequestDataIsNull` event.
  String get statusRequestDataIsNull => values['statusRequestDataIsNull']!;

  /// Message of the `statusRequestSuccess` event.
  String get statusRequestSuccess => values['statusRequestSuccess']!;

  /// Message of the `statusRequestFailed` event.
  String get statusRequestFailed => values['statusRequestFailed']!;

  /// Message of the `unSuspendRequestDataIsNull` event.
  String get unSuspendRequestDataIsNull =>
      values['unSuspendRequestDataIsNull']!;

  /// Message of the `unSuspendRequestSuccessful` event.
  String get unSuspendRequestSuccessful =>
      values['unSuspendRequestSuccessful']!;

  /// Message of the `unSuspendRequestFailed` event.
  String get unSuspendRequestFailed => values['unSuspendRequestFailed']!;

  /// Message of the `pushDataIsNull` event.
  String get pushDataIsNull => values['pushDataIsNull']!;

  /// Message of the `notificationErr` event.
  String get notificationErr => values['notificationErr']!;

  /// Message of the `channelNotCreated` event.
  String get channelNotCreated => values['channelNotCreated']!;

  /// Message of the `pushPermissionDenied` event.
  String get pushPermissionDenied => values['pushPermissionDenied']!;

  /// Message of the `pushIsPosted` event.
  String get pushIsPosted => values['pushIsPosted']!;

  /// Message of the `acPush` event.
  String get acPush => values['acPush']!;

  /// Message of the `notAcPush` event.
  String get notAcPush => values['notAcPush']!;

  /// Message of the `duplicatePushMessage` event.
  String get duplicatePushMessage => values['duplicatePushMessage']!;

  /// Message of the `receiverRedefined` event.
  String get receiverRedefined => values['receiverRedefined']!;

  /// Message of the `errorImgLoad` event.
  String get errorImgLoad => values['errorImgLoad']!;

  /// Message of the `successImgLoad` event.
  String get successImgLoad => values['successImgLoad']!;

  /// Message of the `pushReceive` event.
  String get pushReceive => values['pushReceive']!;

  /// Message of the `pushTokenUpdateAwait` event.
  String get pushTokenUpdateAwait => values['pushTokenUpdateAwait']!;

  /// Message of the `apnsIsNotUpdated` event.
  String get apnsIsNotUpdated => values['apnsIsNotUpdated']!;

  /// Message of the `errorHandleUserInfo` event.
  String get errorHandleUserInfo => values['errorHandleUserInfo']!;

  /// Message of the `uidIsNil` event.
  String get uidIsNil => values['uidIsNil']!;

  /// Message of the `errorMediaDownload` event.
  String get errorMediaDownload => values['errorMediaDownload']!;

  /// Message of the `errorMediaKeyMissing` event.
  String get errorMediaKeyMissing => values['errorMediaKeyMissing']!;

  /// Message of the `errorButtonsKeyMissing` event.
  String get errorButtonsKeyMissing => values['errorButtonsKeyMissing']!;

  /// Message of the `invalidButtonIdentifier` event.
  String get invalidButtonIdentifier => values['invalidButtonIdentifier']!;

  /// Message of the `outOfRangeForIdentifier` event.
  String get outOfRangeForIdentifier => values['outOfRangeForIdentifier']!;

  /// Message of the `unknownButtonIdentifier` event.
  String get unknownButtonIdentifier => values['unknownButtonIdentifier']!;

  /// Message of the `invalidPushProviders` event.
  String get invalidPushProviders => values['invalidPushProviders']!;

  /// Message of the `pushTokenIsNil` event.
  String get pushTokenIsNil => values['pushTokenIsNil']!;

  /// Message of the `subscribeRequestDataIsNil` event.
  String get subscribeRequestDataIsNil => values['subscribeRequestDataIsNil']!;

  /// Message of the `updateRequestDataIsNil` event.
  String get updateRequestDataIsNil => values['updateRequestDataIsNil']!;

  /// Message of the `pushEventRequestDataIsNil` event.
  String get pushEventRequestDataIsNil => values['pushEventRequestDataIsNil']!;

  /// Message of the `unsuspendRequestDataIsNil` event.
  String get unsuspendRequestDataIsNil => values['unsuspendRequestDataIsNil']!;

  /// Message of the `pushStatusRequestDataIsNil` event.
  String get pushStatusRequestDataIsNil =>
      values['pushStatusRequestDataIsNil']!;

  /// Message of the `invalidSubRequestData` event.
  String get invalidSubRequestData => values['invalidSubRequestData']!;

  /// Message of the `invalidPushEventRequestData` event.
  String get invalidPushEventRequestData =>
      values['invalidPushEventRequestData']!;

  /// Message of the `pushConfigurationSaveFailed` event.
  String get pushConfigurationSaveFailed =>
      values['pushConfigurationSaveFailed']!;

  /// Message of the `pushConfigurationClearFailed` event.
  String get pushConfigurationClearFailed =>
      values['pushConfigurationClearFailed']!;

  /// Message of the `pushUnsubscribeRequestSuccessful` event.
  String get pushUnsubscribeRequestSuccessful =>
      values['pushUnsubscribeRequestSuccessful']!;

  /// Message of the `pushSubscribeRequestSuccessful` event.
  String get pushSubscribeRequestSuccessful =>
      values['pushSubscribeRequestSuccessful']!;

  /// Message of the `pushSuspendRequestSuccessful` event.
  String get pushSuspendRequestSuccessful =>
      values['pushSuspendRequestSuccessful']!;

  /// Message of the `pushStatusRequestSuccessful` event.
  String get pushStatusRequestSuccessful =>
      values['pushStatusRequestSuccessful']!;

  /// Message of the `pushEventRequestSuccessful` event.
  String get pushEventRequestSuccessful =>
      values['pushEventRequestSuccessful']!;

  /// Message of the `unsuspendRequestSuccessful` event.
  String get unsuspendRequestSuccessful =>
      values['unsuspendRequestSuccessful']!;

  /// Message of the `pushUnsubscribeRequestFailed` event.
  String get pushUnsubscribeRequestFailed =>
      values['pushUnsubscribeRequestFailed']!;

  /// Message of the `pushSubscribeRequestFailed` event.
  String get pushSubscribeRequestFailed =>
      values['pushSubscribeRequestFailed']!;

  /// Message of the `pushSuspendRequestFailed` event.
  String get pushSuspendRequestFailed => values['pushSuspendRequestFailed']!;

  /// Message of the `pushStatusRequestFailed` event.
  String get pushStatusRequestFailed => values['pushStatusRequestFailed']!;

  /// Message of the `pushEventRequestFailed` event.
  String get pushEventRequestFailed => values['pushEventRequestFailed']!;

  /// Message of the `unsuspendRequestFailed` event.
  String get unsuspendRequestFailed => values['unsuspendRequestFailed']!;
}

/// Push module events resolved for the current platform.
const PushModuleEvents pushModuleEvents = PushModuleEvents._();
