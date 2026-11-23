import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:altcraft_core/altcraft_core.dart';

/// Platform interface for the Altcraft umbrella plugin.
///
/// The umbrella plugin handles full SDK initialization: it assembles the core
/// configuration together with the connected module configurations (push
/// notification icon, In-App placement options) on the native side.
abstract class AltcraftSdkPlatformInterface extends PlatformInterface {
  /// Constructs a AltcraftSdkPlatformInterface.
  AltcraftSdkPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AltcraftSdkPlatformInterface _instance = _ImplementationNotAvailable();

  /// The default instance of [AltcraftSdkPlatformInterface] to use.
  static AltcraftSdkPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AltcraftSdkPlatformInterface].
  static set instance(AltcraftSdkPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the Altcraft SDK with the given configuration.
  ///
  /// Applies core parameters and the initialization options of the connected
  /// modules (push notification icon and channel, In-App placement settings).
  Future<void> initialize(AltcraftConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }
}

/// Throws [UnimplementedError] for all methods.
class _ImplementationNotAvailable extends AltcraftSdkPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The method ${invocation.memberName} is not available. '
      'Is the altcraft plugin properly installed?',
    );
  }
}
