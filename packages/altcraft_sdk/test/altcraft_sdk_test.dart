import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_sdk/altcraft_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AltcraftSDK facade', () {
    test('platform is settable and updates interface instance', () {
      final mock = _MockSdkPlatform();
      AltcraftSDK.platform = mock;
      expect(AltcraftSDK.platform, equals(mock));
      expect(AltcraftSdkPlatformInterface.instance, equals(mock));
    });

    test('initialize delegates to platform', () async {
      final mock = _MockSdkPlatform();
      AltcraftSDK.platform = mock;

      const config = AltcraftConfig(
        apiUrl: 'https://test.com',
        enableLogging: true,
      );
      await AltcraftSDK.initialize(config);

      expect(mock.initializedWith, equals(config));
    });

    test('pushSubscribe delegates to AltcraftPush', () async {
      final mock = _MockSdkPlatform();
      AltcraftSDK.platform = mock;
      final pushMock = _MockPushDelegation();
      AltcraftPush.platform = pushMock;

      await AltcraftSDK.pushSubscribe(sync: true);

      expect(pushMock.subscribeCalls, 1);
      expect(pushMock.lastSync, isTrue);
    });

    test('inAppSubscribe delegates to AltcraftInApp', () async {
      final mock = _MockSdkPlatform();
      AltcraftSDK.platform = mock;
      final inAppMock = _MockInAppDelegation();
      AltcraftInApp.platform = inAppMock;

      await AltcraftSDK.inAppSubscribe(sync: false);

      expect(inAppMock.subscribeCalls, 1);
      expect(inAppMock.lastSync, isFalse);
    });

    test('sendTarget delegates to AltcraftTarget', () async {
      final mock = _MockSdkPlatform();
      AltcraftSDK.platform = mock;
      final targetMock = _MockTargetDelegation();
      AltcraftTarget.platform = targetMock;

      await AltcraftSDK.sendTarget(sid: 'sid-1', eventName: 'purchase');

      expect(targetMock.lastSid, 'sid-1');
      expect(targetMock.lastEventName, 'purchase');
    });

    test('updateProfileFields delegates to AltcraftProfile', () async {
      final mock = _MockSdkPlatform();
      AltcraftSDK.platform = mock;
      final profileMock = _MockProfileDelegation();
      AltcraftProfile.platform = profileMock;

      await AltcraftSDK.updateProfileFields(profileFields: {'name': 'John'});

      expect(profileMock.lastFields, {'name': 'John'});
    });

    test('core methods delegate to AltcraftCore', () async {
      final mock = _MockSdkPlatform();
      AltcraftSDK.platform = mock;
      final coreMock = _MockCoreDelegation();
      AltcraftCore.platform = coreMock;

      await AltcraftSDK.setJwtProvider(() async => 'token');
      await AltcraftSDK.authenticate();
      final authenticated = await AltcraftSDK.isAuthenticated();
      AltcraftSDK.subscribeToEvents();

      expect(coreMock.jwtProviderSet, isTrue);
      expect(coreMock.authenticated, isTrue);
      expect(authenticated, isTrue);
      expect(coreMock.eventsSubscribed, isTrue);
    });
  });
}

class _MockSdkPlatform extends AltcraftSdkPlatformInterface {
  AltcraftConfig? initializedWith;

  @override
  Future<void> initialize(AltcraftConfig config) async {
    initializedWith = config;
  }
}

class _MockPushDelegation extends AltcraftPushPlatformInterface {
  int subscribeCalls = 0;
  bool? lastSync;

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
    lastSync = sync;
  }
}

class _MockInAppDelegation extends AltcraftInAppPlatformInterface {
  int subscribeCalls = 0;
  bool? lastSync;

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
    lastSync = sync;
  }
}

class _MockTargetDelegation extends AltcraftTargetPlatformInterface {
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

class _MockProfileDelegation extends AltcraftProfilePlatformInterface {
  Map<String, dynamic>? lastFields;

  @override
  Future<void> updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) async {
    lastFields = profileFields;
  }
}

class _MockCoreDelegation extends AltcraftCorePlatformInterface {
  bool jwtProviderSet = false;
  bool authenticated = false;
  bool eventsSubscribed = false;

  @override
  Future<void> setJwtProvider(Future<String?> Function() provider) async {
    jwtProviderSet = true;
  }

  @override
  Future<void> authenticate() async {
    authenticated = true;
  }

  @override
  Future<bool> isAuthenticated() async {
    return true;
  }

  @override
  Stream<SdkEvent> subscribeToEvents() {
    eventsSubscribed = true;
    return const Stream.empty();
  }
}
