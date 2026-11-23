import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AltcraftCore', () {
    test('platform is settable and updates interface instance', () {
      final mock = _MockCorePlatform();
      AltcraftCore.platform = mock;
      expect(AltcraftCore.platform, equals(mock));
      expect(AltcraftCorePlatformInterface.instance, equals(mock));
    });

    test('initialize delegates to platform', () async {
      final mock = _MockCorePlatform();
      AltcraftCore.platform = mock;

      const config = AltcraftConfig(apiUrl: 'https://test.com');
      await AltcraftCore.initialize(config);

      expect(mock.initializedWith, equals(config));
    });

    test('subscribeToEvents delegates to platform', () {
      final mock = _MockCorePlatform();
      AltcraftCore.platform = mock;

      AltcraftCore.subscribeToEvents();

      expect(mock.eventsSubscribed, isTrue);
    });

    test('authentication methods delegate to platform', () async {
      final mock = _MockCorePlatform();
      AltcraftCore.platform = mock;

      await AltcraftCore.setJwtProvider(() async => 'token');
      await AltcraftCore.authenticate();
      await AltcraftCore.logOut();
      final authenticated = await AltcraftCore.isAuthenticated();

      expect(mock.jwtProviderSet, isTrue);
      expect(mock.authenticated, isTrue);
      expect(mock.loggedOut, isTrue);
      expect(authenticated, isTrue);
    });
  });
  group('CoreModuleEvents', () {
    test('keeps native catalogs of both platforms', () {
      expect(
        CoreModuleEvents.android['configIsSet'],
        'SDK configuration is installed',
      );
      expect(
        CoreModuleEvents.ios['configSet'],
        'SDK configuration is installed.',
      );
      expect(AltcraftCore.moduleEvents.configIsSet, isNotEmpty);
    });

    test('resolves shared messages for each platform', () {
      expect(
        CoreModuleEvents.valuesFor(TargetPlatform.android)['userLogOut'],
        'User logged out. Anonymous session started.',
      );
      expect(
        CoreModuleEvents.valuesFor(TargetPlatform.iOS)['userLogOut'],
        'User logged out. Anonymous session started',
      );
    });

    test('keeps single-platform names for both platforms', () {
      final android = CoreModuleEvents.valuesFor(TargetPlatform.android);
      final ios = CoreModuleEvents.valuesFor(TargetPlatform.iOS);
      expect(android['configSet'], CoreModuleEvents.ios['configSet']);
      expect(ios['apiUrlIsBlank'], CoreModuleEvents.android['apiUrlIsBlank']);
    });
  });
}

class _MockCorePlatform extends AltcraftCorePlatformInterface {
  AltcraftConfig? initializedWith;
  bool eventsSubscribed = false;
  bool jwtProviderSet = false;
  bool authenticated = false;
  bool loggedOut = false;

  @override
  Future<void> initialize(AltcraftConfig config) async {
    initializedWith = config;
  }

  @override
  Stream<SdkEvent> subscribeToEvents() {
    eventsSubscribed = true;
    return const Stream.empty();
  }

  @override
  Future<void> setJwtProvider(Future<String?> Function() provider) async {
    jwtProviderSet = true;
  }

  @override
  Future<void> authenticate() async {
    authenticated = true;
  }

  @override
  Future<void> logOut() async {
    loggedOut = true;
  }

  @override
  Future<bool> isAuthenticated() async {
    return true;
  }
}
