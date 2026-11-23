import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_core/altcraft_core.dart';

void main() {
  group('AltcraftConfig', () {
    test('toMap includes core fields and module configurations', () {
      const config = AltcraftConfig(
        apiUrl: 'https://test.com',
        appInfo: AppInfo(appID: 'app1', appIID: 'iid1', appVer: '1.0.0'),
        enableLogging: true,
        moduleConfigs: {
          'push': {
            'providerPriority': ['android-firebase']
          },
        },
      );

      final map = config.toMap();
      expect(map['apiUrl'], 'https://test.com');
      expect(map['appInfo']['appID'], 'app1');
      expect(map['moduleConfigs'], {
        'push': {
          'providerPriority': ['android-firebase']
        },
      });
      expect(map['enableLogging'], true);
      expect(map['rToken'], isNull);
    });

    test('toMap omits empty module configurations', () {
      const config = AltcraftConfig(apiUrl: 'https://test.com');
      expect(config.toMap().containsKey('moduleConfigs'), isFalse);
    });
  });

  group('AltcraftConfigBuilder', () {
    test('builds config with module entries', () {
      final config = AltcraftConfigBuilder(
        apiUrl: 'https://test.com',
        rToken: 'token',
        enableLogging: false,
      ).addModuleConfiguration('push', {
        'providerPriority': ['ios-apns']
      }).addModuleConfiguration('inapp', {'maxPlacements': 50}).build();

      expect(config.apiUrl, 'https://test.com');
      expect(config.rToken, 'token');
      expect(config.enableLogging, false);
      expect(config.moduleConfigs, {
        'push': {
          'providerPriority': ['ios-apns']
        },
        'inapp': {'maxPlacements': 50},
      });
    });

    test('later module configuration replaces the previous one', () {
      final config = AltcraftConfigBuilder(apiUrl: 'https://test.com')
          .addModuleConfiguration('push', {'max': 1}).addModuleConfiguration(
              'push', {'max': 2}).build();

      expect(config.moduleConfigs['push'], {'max': 2});
    });
  });

  group('SdkEvent', () {
    test('fromMap parses event correctly', () {
      final event = SdkEvent.fromMap({
        'function': 'pushSubscribe',
        'code': 200,
        'message': 'OK',
        'type': 'event',
        'value': {'key': 'value'},
      });

      expect(event.function, 'pushSubscribe');
      expect(event.code, 200);
      expect(event.message, 'OK');
      expect(event.type, 'event');
      expect(event.value?['key'], 'value');
    });

    test('fromMap handles null values', () {
      final event = SdkEvent.fromMap({
        'function': null,
        'code': null,
        'message': null,
        'type': null,
        'value': null,
      });

      expect(event.function, '');
      expect(event.code, isNull);
      expect(event.message, '');
      expect(event.type, 'event');
      expect(event.value, isNull);
    });
  });

  group('ActionFieldBuilder', () {
    test('set creates correct map', () {
      final result = actionField('age').set(25);
      expect(result['age']['action'], 'set');
      expect(result['age']['value'], 25);
    });

    test('unset creates correct map', () {
      final result = actionField('name').unset(null);
      expect(result['name']['action'], 'unset');
    });

    test('incr creates correct map', () {
      final result = actionField('count').incr(1);
      expect(result['count']['action'], 'incr');
      expect(result['count']['value'], 1);
    });
  });

  group('ResponseWithHttpCode', () {
    test('fromMap parses snake_case correctly', () {
      final response = ResponseWithHttpCode.fromMap({
        'http_code': 200,
        'response': {'profile': {}},
      });
      expect(response.httpCode, 200);
      expect(response.response?['profile'], isNotNull);
    });

    test('fromMap parses camelCase correctly', () {
      final response = ResponseWithHttpCode.fromMap({
        'httpCode': 201,
        'response': {'error': null},
      });
      expect(response.httpCode, 201);
      expect(response.response?['error'], isNull);
    });

    test('fromMap prefers snake_case over camelCase', () {
      final response = ResponseWithHttpCode.fromMap({
        'http_code': 200,
        'httpCode': 404,
        'response': {'ok': true},
      });
      expect(response.httpCode, 200);
    });

    test('fromMap handles null response', () {
      final response = ResponseWithHttpCode.fromMap({
        'http_code': 500,
        'response': null,
      });
      expect(response.httpCode, 500);
      expect(response.response, isNull);
    });

    test('fromMap handles missing fields', () {
      final response = ResponseWithHttpCode.fromMap({});
      expect(response.httpCode, 0);
      expect(response.response, isNull);
    });
  });

  group('AltcraftException', () {
    test('toString includes code and message', () {
      const ex = AltcraftException(code: 'ERR', message: 'failed');
      expect(ex.toString(), contains('ERR'));
      expect(ex.toString(), contains('failed'));
    });

    test('SdkNotInitializedException has correct code', () {
      const ex = SdkNotInitializedException();
      expect(ex.code, 'SDK_NOT_INITIALIZED');
    });
  });

  group('AltcraftChannels', () {
    test('channel names are stable', () {
      expect(AltcraftChannels.sdk, 'com.altcraft/sdk');
      expect(AltcraftChannels.core, 'com.altcraft/core');
      expect(AltcraftChannels.push, 'com.altcraft/push');
      expect(AltcraftChannels.inApp, 'com.altcraft/inapp');
      expect(AltcraftChannels.target, 'com.altcraft/target');
      expect(AltcraftChannels.profile, 'com.altcraft/profile');
      expect(AltcraftChannels.events, 'com.altcraft/events');
    });
  });
}
