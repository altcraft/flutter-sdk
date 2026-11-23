import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for the Altcraft profile module.
abstract class AltcraftProfilePlatformInterface extends PlatformInterface {
  /// Constructs a [AltcraftProfilePlatformInterface].
  AltcraftProfilePlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AltcraftProfilePlatformInterface _instance =
      _ImplementationNotAvailable();

  /// The default instance of [AltcraftProfilePlatformInterface] to use.
  static AltcraftProfilePlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AltcraftProfilePlatformInterface].
  static set instance(AltcraftProfilePlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Updates profile fields on the server.
  Future<void> updateProfileFields({
    Map<String, dynamic>? profileFields,
    bool? skipTriggers,
  }) {
    throw UnimplementedError('updateProfileFields() has not been implemented.');
  }
}

/// Throws [UnimplementedError] for all methods.
class _ImplementationNotAvailable extends AltcraftProfilePlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The method ${invocation.memberName} is not available. '
      'Is the altcraft_profile plugin properly installed?',
    );
  }
}
