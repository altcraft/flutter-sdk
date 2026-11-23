import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_target/altcraft_target.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AltcraftTarget', () {
    test('platform is settable and updates interface instance', () {
      final mock = _MockTargetPlatform();
      AltcraftTarget.platform = mock;
      expect(AltcraftTarget.platform, equals(mock));
      expect(AltcraftTargetPlatformInterface.instance, equals(mock));
    });

    test('sendTarget delegates to platform', () async {
      final mock = _MockTargetPlatform();
      AltcraftTarget.platform = mock;

      await AltcraftTarget.sendTarget(sid: 'sid-1', eventName: 'purchase');

      expect(mock.lastSid, 'sid-1');
      expect(mock.lastEventName, 'purchase');
    });
  });
  group('Subscription', () {
    test('email factory creates correct type', () {
      final sub = Subscription.email(resourceId: 1, email: 'test@test.com');
      expect(sub.type, 'email');
      expect(sub.email, 'test@test.com');
      expect(sub.toMap()['type'], 'email');
    });

    test('email toMap includes channel field', () {
      final sub = Subscription.email(resourceId: 1, email: 'test@test.com');
      final map = sub.toMap();
      expect(map['channel'], 'email');
      expect(map['type'], 'email');
    });

    test('sms factory creates correct type', () {
      final sub = Subscription.sms(resourceId: 1, phone: '+1234567890');
      expect(sub.type, 'sms');
      expect(sub.phone, '+1234567890');
    });

    test('sms toMap includes channel field', () {
      final sub = Subscription.sms(resourceId: 1, phone: '+1234567890');
      final map = sub.toMap();
      expect(map['channel'], 'sms');
      expect(map['type'], 'sms');
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

    test('push toMap includes channel field', () {
      final sub = Subscription.push(
        resourceId: 1,
        provider: 'ios-apns',
        subscriptionId: 'sub-1',
      );
      final map = sub.toMap();
      expect(map['channel'], 'push');
      expect(map['type'], 'push');
    });

    test('ccData factory creates correct type', () {
      final sub = Subscription.ccData(
        resourceId: 1,
        channel: 'telegram_bot',
        ccData: {'chat_id': 12345},
      );
      expect(sub.type, 'cc_data');
      expect(sub.ccChannel, 'telegram_bot');
      expect(sub.ccData, {'chat_id': 12345});
    });

    test('ccData toMap includes all required fields', () {
      final sub = Subscription.ccData(
        resourceId: 1,
        channel: 'telegram_bot',
        ccData: {'chat_id': 12345},
      );
      final map = sub.toMap();
      expect(map['type'], 'cc_data');
      expect(map['channel'], 'cc_data');
      expect(map['cc_channel'], 'telegram_bot');
      expect(map['cc_data'], {'chat_id': 12345});
      expect(map['resource_id'], 1);
    });

    test('toMap includes resource_id', () {
      final sub = Subscription.email(resourceId: 42, email: 'test@test.com');
      final map = sub.toMap();
      expect(map['resource_id'], 42);
    });

    test('toMap omits null fields', () {
      final sub = Subscription.email(resourceId: 1, email: 'test@test.com');
      final map = sub.toMap();
      expect(map['phone'], isNull);
      expect(map['provider'], isNull);
      expect(map['cc_data'], isNull);
    });
  });

  group('UTM', () {
    test('toMap includes non-null fields', () {
      const utm = UTM(source: 'app', medium: 'push', campaign: 'test');
      final map = utm.toMap();
      expect(map['source'], 'app');
      expect(map['medium'], 'push');
      expect(map['campaign'], 'test');
      expect(map['content'], isNull);
    });
  });

  group('TargetModuleEvents', () {
    test('keeps native catalogs of both platforms', () {
      expect(
        TargetModuleEvents.android['requestSuccessful'],
        'successful target request: event/post',
      );
      expect(
        TargetModuleEvents.ios['mobileEventRequestSuccessful'],
        'successful request: event/post',
      );
      expect(AltcraftTarget.moduleEvents.requestSuccessful, isNotEmpty);
    });
  });
}

class _MockTargetPlatform extends AltcraftTargetPlatformInterface {
  String? lastSid;
  String? lastEventName;

  @override
  Future<void> sendTarget({
    required String sid,
    required String eventName,
    String? sendMessageId,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? matching,
    String? matchingType,
    Map<String, dynamic>? profileFields,
    Subscription? subscription,
    UTM? utm,
  }) async {
    lastSid = sid;
    lastEventName = eventName;
  }
}
