import 'models/subscription.dart';
import 'models/utm.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for the Altcraft target module.
abstract class AltcraftTargetPlatformInterface extends PlatformInterface {
  /// Constructs a [AltcraftTargetPlatformInterface].
  AltcraftTargetPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AltcraftTargetPlatformInterface _instance =
      _ImplementationNotAvailable();

  /// The default instance of [AltcraftTargetPlatformInterface] to use.
  static AltcraftTargetPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AltcraftTargetPlatformInterface].
  static set instance(AltcraftTargetPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Sends a mobile event to the Altcraft platform.
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
  }) {
    throw UnimplementedError('sendTarget() has not been implemented.');
  }
}

/// Throws [UnimplementedError] for all methods.
class _ImplementationNotAvailable extends AltcraftTargetPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The method ${invocation.memberName} is not available. '
      'Is the altcraft_target plugin properly installed?',
    );
  }
}
