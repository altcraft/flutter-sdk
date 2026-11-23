import 'package:flutter/services.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'altcraft_inapp_platform_interface.dart';
import 'models/in_app_animation.dart';

/// MethodChannel implementation of [AltcraftInAppPlatformInterface].
class MethodChannelAltcraftInApp extends AltcraftInAppPlatformInterface {
  final MethodChannel _channel = const MethodChannel(AltcraftChannels.inApp);

  void Function(String json)? _jsonContentHandler;

  /// Creates a new instance using [MethodChannel] for communication.
  MethodChannelAltcraftInApp() {
    AltcraftInAppPlatformInterface.instance = this;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  @override
  Future<void> jsonContentSubscribe(void Function(String json) handler) async {
    _jsonContentHandler = handler;
    await _invokeSilently('jsonContentSubscribe');
  }

  @override
  Future<void> jsonContentUnsubscribe() async {
    _jsonContentHandler = null;
    await _invokeSilently('jsonContentUnsubscribe');
  }

  /// Handles calls initiated by the native side.
  ///
  /// JSON content of JSON-content campaigns is forwarded by the native side
  /// when such a campaign is triggered.
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onJsonContent') {
      final json = call.arguments;
      if (json is String) {
        _jsonContentHandler?.call(json);
      }
    }
    return null;
  }

  /// Invokes a channel method that manages the native subscription.
  ///
  /// Errors are ignored: a missing native implementation must not break the
  /// Dart stream lifecycle.
  Future<void> _invokeSilently(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      // Ignored on purpose.
    } on MissingPluginException {
      // Ignored on purpose.
    }
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
    try {
      await _channel.invokeMethod('inAppSubscribe', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats?.map((c) => c.toMap()).toList(),
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'inAppSubscribe failed');
    }
  }

  @override
  Future<void> inAppUnsubscribe({
    bool? sync,
    Map<String, dynamic>? profileFields,
    Map<String, dynamic>? customFields,
    List<CategoryData>? cats,
    bool? replace,
    bool? skipTriggers,
  }) async {
    try {
      await _channel.invokeMethod('inAppUnsubscribe', {
        'sync': sync,
        'profileFields': profileFields,
        'customFields': customFields,
        'cats': cats?.map((c) => c.toMap()).toList(),
        'replace': replace,
        'skipTriggers': skipTriggers,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'inAppUnsubscribe failed');
    }
  }

  @override
  Future<void> setScreen(String screen) async {
    try {
      await _channel.invokeMethod('setScreen', {'screen': screen});
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'setScreen failed');
    }
  }

  @override
  Future<void> trigger(String name) async {
    try {
      await _channel.invokeMethod('trigger', {'name': name});
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'trigger failed');
    }
  }

  @override
  Future<void> getPlacements() async {
    try {
      await _channel.invokeMethod('getPlacements');
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'getPlacements failed');
    }
  }

  @override
  Future<void> setAnimations(List<InAppAnimation> animations) async {
    try {
      await _channel.invokeMethod('setAnimations', {
        'animations': animations.map((animation) => animation.toMap()).toList(),
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'setAnimations failed');
    }
  }
}
