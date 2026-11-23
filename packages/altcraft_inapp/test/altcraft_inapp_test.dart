import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_inapp/altcraft_inapp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AltcraftInApp', () {
    test('platform is settable and updates interface instance', () {
      final mock = _MockInAppPlatform();
      AltcraftInApp.platform = mock;
      expect(AltcraftInApp.platform, equals(mock));
      expect(AltcraftInAppPlatformInterface.instance, equals(mock));
    });

    test('inAppSubscribe delegates to platform', () async {
      final mock = _MockInAppPlatform();
      AltcraftInApp.platform = mock;

      await AltcraftInApp.inAppSubscribe(sync: true);

      expect(mock.subscribeCalls, 1);
    });

    test('setScreen delegates to platform', () async {
      final mock = _MockInAppPlatform();
      AltcraftInApp.platform = mock;

      await AltcraftInApp.setScreen('home');

      expect(mock.lastScreen, 'home');
    });

    test('trigger delegates to platform', () async {
      final mock = _MockInAppPlatform();
      AltcraftInApp.platform = mock;

      await AltcraftInApp.trigger('tr_modal');

      expect(mock.lastTrigger, 'tr_modal');
    });

    test('setAnimations delegates to platform', () async {
      final mock = _MockInAppPlatform();
      AltcraftInApp.platform = mock;

      await AltcraftInApp.setAnimations([
        const InAppAnimation(companyId: 347),
        const InAppAnimation(alphaFrom: 0),
      ]);

      expect(mock.animations, hasLength(2));
      expect(mock.animations!.first.companyId, 347);
      expect(mock.animations!.last.companyId, isNull);
    });

    test('jsonContent delegates to platform', () async {
      final mock = _MockInAppPlatform();
      AltcraftInApp.platform = mock;

      void handler(String json) {}

      await AltcraftInApp.jsonContent.subscribe(handler);
      expect(mock.jsonHandler, same(handler));

      await AltcraftInApp.jsonContent.unsubscribe();
      expect(mock.jsonHandler, isNull);
    });
  });

  group('InAppConfig builder extension', () {
    test('adds the In-App module configuration', () {
      final config = AltcraftConfigBuilder(apiUrl: 'https://test.com')
          .inAppConfig(const InAppConfig(
            inAppAutoRequest: false,
            placementsRequestInterval: Duration(minutes: 20),
            maxPlacements: 50,
          ))
          .build();

      expect(config.moduleConfigs['inapp'], {
        'inAppAutoRequest': false,
        'placementsRequestIntervalMs': 20 * 60 * 1000,
        'maxPlacements': 50,
      });
    });

    test('uses native defaults', () {
      final config = AltcraftConfigBuilder(apiUrl: 'https://test.com')
          .inAppConfig(const InAppConfig())
          .build();

      expect(config.moduleConfigs['inapp'], {
        'inAppAutoRequest': true,
        'placementsRequestIntervalMs': 30 * 60 * 1000,
        'maxPlacements': 500,
      });
    });
  });

  group('MethodChannelAltcraftInApp', () {
    const channel = MethodChannel(AltcraftChannels.inApp);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    test('manages the native subscription and forwards JSON content', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });

      final implementation = MethodChannelAltcraftInApp();
      final received = <String>[];
      await implementation.jsonContentSubscribe(received.add);
      expect(calls, contains('jsonContentSubscribe'));

      final data = const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('onJsonContent', '{"a":1}'));
      await messenger.handlePlatformMessage(channel.name, data, (_) {});

      expect(received, ['{"a":1}']);

      await implementation.jsonContentUnsubscribe();
      expect(calls, contains('jsonContentUnsubscribe'));

      await messenger.handlePlatformMessage(channel.name, data, (_) {});
      expect(received, ['{"a":1}']);

      messenger.setMockMethodCallHandler(channel, null);
    });

    test('serializes categories for the native subscription', () async {
      Map<Object?, Object?>? arguments;
      messenger.setMockMethodCallHandler(channel, (call) async {
        arguments = call.arguments as Map<Object?, Object?>?;
        return null;
      });

      final implementation = MethodChannelAltcraftInApp();
      await implementation.inAppSubscribe(
        sync: true,
        cats: const [CategoryData(name: 'news', active: true)],
      );

      expect(arguments?['cats'], [
        {'name': 'news', 'active': true},
      ]);

      messenger.setMockMethodCallHandler(channel, null);
    });
  });

  group('InAppAnimation', () {
    test('toMap uses default values', () {
      const animation = InAppAnimation();

      expect(animation.toMap(), {
        'companyId': null,
        'alphaFrom': null,
        'alphaTo': null,
        'translateXFrom': null,
        'translateXTo': null,
        'translateYFrom': null,
        'translateYTo': null,
        'scaleXFrom': null,
        'scaleXTo': null,
        'scaleYFrom': null,
        'scaleYTo': null,
        'rotationFrom': null,
        'rotationTo': null,
        'durationMs': 350,
        'delayMs': 0,
        'easing': 'easeInOut',
      });
    });

    test('toMap serializes explicit values', () {
      const animation = InAppAnimation(
        companyId: 347,
        alphaFrom: 0,
        alphaTo: 1,
        translateXFrom: 12.5,
        translateXTo: 0,
        translateYFrom: 120,
        translateYTo: 0,
        scaleXFrom: 0.95,
        scaleXTo: 1,
        scaleYFrom: 0.9,
        scaleYTo: 1,
        rotationFrom: -90,
        rotationTo: 0,
        duration: Duration(milliseconds: 350),
        delay: Duration(milliseconds: 100),
        easing: InAppAnimationEasing.easeInOut,
      );

      expect(animation.toMap(), {
        'companyId': 347,
        'alphaFrom': 0.0,
        'alphaTo': 1.0,
        'translateXFrom': 12.5,
        'translateXTo': 0.0,
        'translateYFrom': 120.0,
        'translateYTo': 0.0,
        'scaleXFrom': 0.95,
        'scaleXTo': 1.0,
        'scaleYFrom': 0.9,
        'scaleYTo': 1.0,
        'rotationFrom': -90.0,
        'rotationTo': 0.0,
        'durationMs': 350,
        'delayMs': 100,
        'easing': 'easeInOut',
      });
    });

    test('easing names match the platform identifiers', () {
      expect(InAppAnimationEasing.linear.name, 'linear');
      expect(InAppAnimationEasing.easeIn.name, 'easeIn');
      expect(InAppAnimationEasing.easeOut.name, 'easeOut');
      expect(InAppAnimationEasing.easeInOut.name, 'easeInOut');
    });
  });
  group('InAppModuleEvents', () {
    test('keeps native catalogs of both platforms', () {
      expect(InAppModuleEvents.android['maxPlacementsInvalid'], isNotEmpty);
      expect(InAppModuleEvents.ios['maxPlacementsInvalid'], isNotEmpty);
      expect(
        InAppModuleEvents.ios['requestIntervalInvalid'],
        'Invalid in-app configuration: placementsRequestInterval must be > 0',
      );
      expect(AltcraftInApp.moduleEvents.maxPlacementsInvalid, isNotEmpty);
    });
  });
}

class _MockInAppPlatform extends AltcraftInAppPlatformInterface {
  int subscribeCalls = 0;
  String? lastScreen;
  String? lastTrigger;
  List<InAppAnimation>? animations;

  void Function(String json)? jsonHandler;

  @override
  Future<void> jsonContentSubscribe(void Function(String json) handler) async {
    jsonHandler = handler;
  }

  @override
  Future<void> jsonContentUnsubscribe() async {
    jsonHandler = null;
  }

  @override
  Future<void> inAppSubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    subscribeCalls++;
  }

  @override
  Future<void> setScreen(String screen) async {
    lastScreen = screen;
  }

  @override
  Future<void> trigger(String name) async {
    lastTrigger = name;
  }

  @override
  Future<void> setAnimations(List<InAppAnimation> animations) async {
    this.animations = animations;
  }
}
