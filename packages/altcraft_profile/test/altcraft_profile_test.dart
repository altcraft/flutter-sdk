import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_profile/altcraft_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AltcraftProfile', () {
    test('platform is settable and updates interface instance', () {
      final mock = _MockProfilePlatform();
      AltcraftProfile.platform = mock;
      expect(AltcraftProfile.platform, equals(mock));
      expect(AltcraftProfilePlatformInterface.instance, equals(mock));
    });

    test('updateProfileFields delegates to platform', () async {
      final mock = _MockProfilePlatform();
      AltcraftProfile.platform = mock;

      await AltcraftProfile.updateProfileFields(
        profileFields: {'name': 'John'},
        skipTriggers: true,
      );

      expect(mock.lastFields, {'name': 'John'});
      expect(mock.lastSkipTriggers, isTrue);
    });
  });
  group('ProfileModuleEvents', () {
    test('keeps native catalogs of both platforms', () {
      expect(
        ProfileModuleEvents.android['requestSuccessful'],
        'successful request: profile/update',
      );
      expect(
        ProfileModuleEvents.ios['profileUpdateRequestSuccessful'],
        'successful request: profile/update',
      );
      expect(AltcraftProfile.moduleEvents.requestSuccessful, isNotEmpty);
    });
  });
}

class _MockProfilePlatform extends AltcraftProfilePlatformInterface {
  Map<String, dynamic>? lastFields;
  bool? lastSkipTriggers;

  @override
  Future<void> updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) async {
    lastFields = profileFields;
    lastSkipTriggers = skipTriggers;
  }
}
