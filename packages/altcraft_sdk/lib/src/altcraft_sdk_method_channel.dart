import 'package:flutter/services.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'altcraft_sdk_platform_interface.dart';

/// MethodChannel implementation of [AltcraftSdkPlatformInterface].
///
/// The umbrella channel handles full SDK initialization; all other operations
/// are delegated to the module packages over their own channels.
class MethodChannelAltcraftSdk extends AltcraftSdkPlatformInterface {
  final MethodChannel _channel = const MethodChannel(AltcraftChannels.sdk);

  /// Creates a new instance using [MethodChannel] for communication.
  MethodChannelAltcraftSdk() {
    AltcraftSdkPlatformInterface.instance = this;
  }

  @override
  Future<void> initialize(AltcraftConfig config) async {
    try {
      await _channel.invokeMethod('initialize', config.toMap());
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'initialize failed');
    }
  }
}
