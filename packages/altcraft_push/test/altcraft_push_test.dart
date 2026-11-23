import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_push/altcraft_push.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AltcraftPush', () {
    test('platform is settable and updates interface instance', () {
      final mock = _MockPushPlatform();
      AltcraftPush.platform = mock;
      expect(AltcraftPush.platform, equals(mock));
      expect(AltcraftPushPlatformInterface.instance, equals(mock));
    });

    test('pushSubscribe delegates to platform', () async {
      final mock = _MockPushPlatform();
      AltcraftPush.platform = mock;

      await AltcraftPush.pushSubscribe(sync: true, replace: false);

      expect(mock.subscribeCalls, 1);
      expect(mock.lastSubscribeSync, isTrue);
    });

    test('getPushToken delegates to platform', () async {
      final mock = _MockPushPlatform();
      AltcraftPush.platform = mock;

      final token = await AltcraftPush.getPushToken();

      expect(token?.provider, 'ios-apns');
      expect(token?.token, 'abc123');
    });

    test('requestNotificationPermission delegates to platform', () async {
      final mock = _MockPushPlatform();
      AltcraftPush.platform = mock;

      final granted = await AltcraftPush.requestNotificationPermission();

      expect(granted, isTrue);
    });
  });
  group('TokenData', () {
    test('fromMap parses correctly', () {
      final token =
          TokenData.fromMap({'provider': 'ios-apns', 'token': 'abc123'});
      expect(token.provider, 'ios-apns');
      expect(token.token, 'abc123');
    });
  });

  group('PushConfig builder extension', () {
    test('adds the push module configuration', () {
      final config = AltcraftConfigBuilder(apiUrl: 'https://test.com')
          .pushConfig(const PushConfig(
            providerPriority: ['android-firebase'],
            iconName: 'ic_notification',
            pushReceiverModules: ['com.example'],
            pushChannelName: 'news',
            pushChannelDescription: 'News channel',
          ))
          .build();

      expect(config.moduleConfigs['push'], {
        'providerPriority': ['android-firebase'],
        'iconName': 'ic_notification',
        'pushReceiverModules': ['com.example'],
        'pushChannelName': 'news',
        'pushChannelDescription': 'News channel',
      });
    });

    test('empty config produces an empty module map', () {
      final config = AltcraftConfigBuilder(apiUrl: 'https://test.com')
          .pushConfig(const PushConfig())
          .build();

      expect(config.moduleConfigs['push'], isEmpty);
    });
  });

  group('PushModuleEvents', () {
    test('keeps native catalogs of both platforms', () {
      expect(
          PushModuleEvents.android['pushProviderSet'], 'push provider set -');
      expect(PushModuleEvents.ios['pushProviderSet'], 'push provider set: ');
      expect(
        PushModuleEvents.ios['pushReceive'],
        'received Altcraft push notification.',
      );
    });

    test('resolves platform-specific messages', () {
      expect(
        PushModuleEvents.valuesFor(TargetPlatform.iOS)['pushProviderSet'],
        'push provider set: ',
      );
      expect(
        PushModuleEvents.valuesFor(TargetPlatform.android)['pushProviderSet'],
        'push provider set -',
      );
      expect(AltcraftPush.moduleEvents.pushProviderSet, isNotEmpty);
    });
  });
}

class _MockPushPlatform extends AltcraftPushPlatformInterface {
  int subscribeCalls = 0;
  bool? lastSubscribeSync;

  @override
  Future<void> pushSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    subscribeCalls++;
    lastSubscribeSync = sync;
  }

  @override
  Future<TokenData?> getPushToken() async {
    return const TokenData(provider: 'ios-apns', token: 'abc123');
  }

  @override
  Future<bool> requestNotificationPermission() async {
    return true;
  }
}
