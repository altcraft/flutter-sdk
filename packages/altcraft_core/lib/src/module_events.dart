import 'package:flutter/foundation.dart';

/// Core module events.
///
/// Holds the messages emitted by the native SDK. Catalogs of both platforms
/// are merged: a name available on only one platform keeps that platform's
/// message and never matches events on the other platform.
final class CoreModuleEvents {
  const CoreModuleEvents._();

  /// Android event messages.
  static const Map<String, String> android = <String, String>{
    'configIsSet': 'SDK configuration is installed',
    'sdkCleared': 'SDK data has been cleared',
    'notAuthenticatedError': 'User is not authenticated',
    'userLogOut': 'User logged out. Anonymous session started.',
    'apiUrlIsBlank':
        'Invalid configuration: apiUrl must not be empty or blank.',
    'rTokenIsBlank':
        'Invalid configuration: RToken must not be empty or blank.',
    'authDataIsNull':
        'SDK cannot obtain authentication data required to interact with the platform',
    'rTokenChange':
        'Role token change: SDK database data will be cleared, except for configuration data.',
    'configIsNotSet': 'the configuration is not set',
    'sdkInitWaitingExpired': 'SDK initialization timeout has expired',
    'roomMigrationError':
        'Room database migration failed. The local SDK database will be recreated.',
    'authorizeRequestDataIsNull': 'authorize request data is null',
    'authRequestRetryLimit': 'auth request retry limit',
    'configIsNull': 'config data is null',
    'userIsNull': 'userTag is null. It is impossible to identify the user',
    'noInternetConnect':
        'no internet connection, retry when connection is restored',
    'responseDataIsNull': 'response data is null',
    'jwtTokenIsNull': 'JWT token is null',
    'jwtDecodeFailed': 'JWT payload decoding failed',
    'jwtTooLarge':
        'JWT payload exceeds allowed size (16 KB limit): input rejected to prevent DoS',
    'payloadIsMissing': 'JWT does not contain a payload',
    'matchingIsNull': 'matching mode is null',
    'matchingIdIsNull': 'matching claim does not contain a matching ID',
    'internalAuthIsNull': 'internal auth data is null',
    'authHeaderIsNull': 'auth header is null',
    'authenticateSuccessful': 'successful request: profile/authenticate',
    'pushStatusRequestFailed': 'failed request: push/status',
    'authenticateFailed': 'failed request: profile/authenticate',
  };

  /// iOS event messages.
  static const Map<String, String> ios = <String, String>{
    'configSet': 'SDK configuration is installed.',
    'sdkCleared': 'SDK data has been cleared',
    'rTokenChange':
        'Role token change: SDK database data will be cleared, except for configuration data.',
    'initAwait': 'waiting for SDK initialization to complete',
    'userLogOut': 'User logged out. Anonymous session started',
    'backgroundTaskRegister': 'SDK background task is registered',
    'backgroundTaskCompleted': 'SDK background task completed',
    'configIsNotSet': 'the configuration is not set',
    'coreDataError': 'error in CoreData. Re-initialize the SDK.',
    'errorLoadModelInCoreData': 'failed to load model from framework.',
    'appGroupIsNotSet': 'App Group name was not set.',
    'contextIsUnavailable': 'core data context is unavailable',
    'invalidCoreDataEntityName': 'the coreData entity name is not valid',
    'entityNotFoundByID': 'entity not found by ID',
    'coreDataModelNotFoundInBundle':
        'Core Data model was not found in any bundle',
    'coreDataModelMissingEntity':
        'Core Data model is missing the required entity; the model did not load',
    'sdkInitWaitingExpired': 'SDK initialization timeout has expired',
    'notAuthenticatedError': 'user is not authenticated',
    'invalidUrlValue': 'invalid apiUrl value - empty or null.',
    'invalidRTokenValue':
        'invalid resource token value - resource token is empty.',
    'nonJsonObject': 'non-json object has been provided',
    'fieldsIsObjects': 'invalid values: not all values are primitives',
    'configIsNil': 'config data is nil',
    'userTagIsNil': 'userTag is null. It is impossible to identify the user',
    'permissionDenied': 'notification permission denied.',
    'backgroundTaskExpired': 'SDK background task expired',
    'jwtIsNil': 'JWT token is nil',
    'jwtParsingError': 'JWT parsing error',
    'externalAuthDataIsNil': 'external auth data is nil',
    'internalAuthDataIsNil': 'internal auth data is nil',
    'failedCreateRequest': 'Failed to create request.',
    'failedProcessingResponse': 'Failed processing the response',
    'responseDataIsNull': 'response data is null',
    'invalidRequestUrl': 'invalid request url',
    'invalidResponseFormat': 'invalid response format',
    'authenticateSuccessful': 'successful request: profile/authenticate',
    'authenticateFailed': 'failed request: profile/authenticate',
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

  /// Message of the `configIsSet` event.
  String get configIsSet => values['configIsSet']!;

  /// Message of the `sdkCleared` event.
  String get sdkCleared => values['sdkCleared']!;

  /// Message of the `notAuthenticatedError` event.
  String get notAuthenticatedError => values['notAuthenticatedError']!;

  /// Message of the `userLogOut` event.
  String get userLogOut => values['userLogOut']!;

  /// Message of the `apiUrlIsBlank` event.
  String get apiUrlIsBlank => values['apiUrlIsBlank']!;

  /// Message of the `rTokenIsBlank` event.
  String get rTokenIsBlank => values['rTokenIsBlank']!;

  /// Message of the `authDataIsNull` event.
  String get authDataIsNull => values['authDataIsNull']!;

  /// Message of the `rTokenChange` event.
  String get rTokenChange => values['rTokenChange']!;

  /// Message of the `configIsNotSet` event.
  String get configIsNotSet => values['configIsNotSet']!;

  /// Message of the `sdkInitWaitingExpired` event.
  String get sdkInitWaitingExpired => values['sdkInitWaitingExpired']!;

  /// Message of the `roomMigrationError` event.
  String get roomMigrationError => values['roomMigrationError']!;

  /// Message of the `authorizeRequestDataIsNull` event.
  String get authorizeRequestDataIsNull =>
      values['authorizeRequestDataIsNull']!;

  /// Message of the `authRequestRetryLimit` event.
  String get authRequestRetryLimit => values['authRequestRetryLimit']!;

  /// Message of the `configIsNull` event.
  String get configIsNull => values['configIsNull']!;

  /// Message of the `userIsNull` event.
  String get userIsNull => values['userIsNull']!;

  /// Message of the `noInternetConnect` event.
  String get noInternetConnect => values['noInternetConnect']!;

  /// Message of the `responseDataIsNull` event.
  String get responseDataIsNull => values['responseDataIsNull']!;

  /// Message of the `jwtTokenIsNull` event.
  String get jwtTokenIsNull => values['jwtTokenIsNull']!;

  /// Message of the `jwtDecodeFailed` event.
  String get jwtDecodeFailed => values['jwtDecodeFailed']!;

  /// Message of the `jwtTooLarge` event.
  String get jwtTooLarge => values['jwtTooLarge']!;

  /// Message of the `payloadIsMissing` event.
  String get payloadIsMissing => values['payloadIsMissing']!;

  /// Message of the `matchingIsNull` event.
  String get matchingIsNull => values['matchingIsNull']!;

  /// Message of the `matchingIdIsNull` event.
  String get matchingIdIsNull => values['matchingIdIsNull']!;

  /// Message of the `internalAuthIsNull` event.
  String get internalAuthIsNull => values['internalAuthIsNull']!;

  /// Message of the `authHeaderIsNull` event.
  String get authHeaderIsNull => values['authHeaderIsNull']!;

  /// Message of the `authenticateSuccessful` event.
  String get authenticateSuccessful => values['authenticateSuccessful']!;

  /// Message of the `pushStatusRequestFailed` event.
  String get pushStatusRequestFailed => values['pushStatusRequestFailed']!;

  /// Message of the `authenticateFailed` event.
  String get authenticateFailed => values['authenticateFailed']!;

  /// Message of the `configSet` event.
  String get configSet => values['configSet']!;

  /// Message of the `initAwait` event.
  String get initAwait => values['initAwait']!;

  /// Message of the `backgroundTaskRegister` event.
  String get backgroundTaskRegister => values['backgroundTaskRegister']!;

  /// Message of the `backgroundTaskCompleted` event.
  String get backgroundTaskCompleted => values['backgroundTaskCompleted']!;

  /// Message of the `coreDataError` event.
  String get coreDataError => values['coreDataError']!;

  /// Message of the `errorLoadModelInCoreData` event.
  String get errorLoadModelInCoreData => values['errorLoadModelInCoreData']!;

  /// Message of the `appGroupIsNotSet` event.
  String get appGroupIsNotSet => values['appGroupIsNotSet']!;

  /// Message of the `contextIsUnavailable` event.
  String get contextIsUnavailable => values['contextIsUnavailable']!;

  /// Message of the `invalidCoreDataEntityName` event.
  String get invalidCoreDataEntityName => values['invalidCoreDataEntityName']!;

  /// Message of the `entityNotFoundByID` event.
  String get entityNotFoundByID => values['entityNotFoundByID']!;

  /// Message of the `coreDataModelNotFoundInBundle` event.
  String get coreDataModelNotFoundInBundle =>
      values['coreDataModelNotFoundInBundle']!;

  /// Message of the `coreDataModelMissingEntity` event.
  String get coreDataModelMissingEntity =>
      values['coreDataModelMissingEntity']!;

  /// Message of the `invalidUrlValue` event.
  String get invalidUrlValue => values['invalidUrlValue']!;

  /// Message of the `invalidRTokenValue` event.
  String get invalidRTokenValue => values['invalidRTokenValue']!;

  /// Message of the `nonJsonObject` event.
  String get nonJsonObject => values['nonJsonObject']!;

  /// Message of the `fieldsIsObjects` event.
  String get fieldsIsObjects => values['fieldsIsObjects']!;

  /// Message of the `configIsNil` event.
  String get configIsNil => values['configIsNil']!;

  /// Message of the `userTagIsNil` event.
  String get userTagIsNil => values['userTagIsNil']!;

  /// Message of the `permissionDenied` event.
  String get permissionDenied => values['permissionDenied']!;

  /// Message of the `backgroundTaskExpired` event.
  String get backgroundTaskExpired => values['backgroundTaskExpired']!;

  /// Message of the `jwtIsNil` event.
  String get jwtIsNil => values['jwtIsNil']!;

  /// Message of the `jwtParsingError` event.
  String get jwtParsingError => values['jwtParsingError']!;

  /// Message of the `externalAuthDataIsNil` event.
  String get externalAuthDataIsNil => values['externalAuthDataIsNil']!;

  /// Message of the `internalAuthDataIsNil` event.
  String get internalAuthDataIsNil => values['internalAuthDataIsNil']!;

  /// Message of the `failedCreateRequest` event.
  String get failedCreateRequest => values['failedCreateRequest']!;

  /// Message of the `failedProcessingResponse` event.
  String get failedProcessingResponse => values['failedProcessingResponse']!;

  /// Message of the `invalidRequestUrl` event.
  String get invalidRequestUrl => values['invalidRequestUrl']!;

  /// Message of the `invalidResponseFormat` event.
  String get invalidResponseFormat => values['invalidResponseFormat']!;
}

/// Core module events resolved for the current platform.
const CoreModuleEvents coreModuleEvents = CoreModuleEvents._();
