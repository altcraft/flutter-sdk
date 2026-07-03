import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_sdk/altcraft_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AltcraftSDK Platform Interface', () {
    test('platform interface is settable', () {
      final mock = _MockPlatform();
      AltcraftSdkPlatformInterface.instance = mock;
      expect(AltcraftSdkPlatformInterface.instance, equals(mock));
    });
  });

  group('AltcraftConfig', () {
    test('toMap includes all required fields', () {
      final config = const AltcraftConfig(
        apiUrl: 'https://test.com',
        appInfo: AppInfo(appID: 'app1', appIID: 'iid1', appVer: '1.0.0'),
        providerPriorityList: ['android-firebase'],
        enableLogging: true,
      );

      final map = config.toMap();
      expect(map['apiUrl'], 'https://test.com');
      expect(map['appInfo']['appID'], 'app1');
      expect(map['providerPriorityList'], ['android-firebase']);
      expect(map['enableLogging'], true);
      expect(map['rToken'], isNull);
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

  group('TokenData', () {
    test('fromMap parses correctly', () {
      final token = TokenData.fromMap({'provider': 'ios-apns', 'token': 'abc123'});
      expect(token.provider, 'ios-apns');
      expect(token.token, 'abc123');
    });
  });

  group('Subscription', () {
    test('email factory creates correct type', () {
      final sub = Subscription.email(resourceId: 1, email: 'test@test.com');
      expect(sub.type, 'email');
      expect(sub.email, 'test@test.com');
      expect(sub.toMap()['type'], 'email');
    });

    test('sms factory creates correct type', () {
      final sub = Subscription.sms(resourceId: 1, phone: '+1234567890');
      expect(sub.type, 'sms');
      expect(sub.phone, '+1234567890');
    });

    test('push factory creates correct type', () {
      final sub = Subscription.push(
        resourceId: 1,
        provider: 'ios-apns',
        subscriptionId: 'sub-1',
      );
      expect(sub.type, 'push');
      expect(sub.provider, 'ios-apns');
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
    test('fromMap parses correctly', () {
      final response = ResponseWithHttpCode.fromMap({
        'httpCode': 200,
        'response': {'profile': {}},
      });
      expect(response.httpCode, 200);
      expect(response.response?['profile'], isNotNull);
    });
  });

  group('UTM', () {
    test('toMap includes non-null fields', () {
      final utm = const UTM(source: 'app', medium: 'push', campaign: 'test');
      final map = utm.toMap();
      expect(map['source'], 'app');
      expect(map['medium'], 'push');
      expect(map['campaign'], 'test');
      expect(map['content'], isNull);
    });
  });

  group('AltcraftException', () {
    test('toString includes code and message', () {
      final ex = const AltcraftException(code: 'ERR', message: 'failed');
      expect(ex.toString(), contains('ERR'));
      expect(ex.toString(), contains('failed'));
    });

    test('SdkNotInitializedException has correct code', () {
      final ex = const SdkNotInitializedException();
      expect(ex.code, 'SDK_NOT_INITIALIZED');
    });
  });
}

/// Mock platform for testing.
class _MockPlatform extends AltcraftSdkPlatformInterface {
  @override
  Future<void> initialize(AltcraftConfig config) async {
    // no-op
  }
}
