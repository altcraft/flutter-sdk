import 'dart:async';

import 'package:flutter/services.dart';
import 'package:altcraft_core/altcraft_core.dart';

/// MethodChannel implementation of [AltcraftCorePlatformInterface].
class MethodChannelAltcraftCore extends AltcraftCorePlatformInterface {
  final MethodChannel _channel = const MethodChannel(AltcraftChannels.core);
  final EventChannel _eventChannel =
      const EventChannel(AltcraftChannels.events);
  Stream<SdkEvent>? _eventStream;
  Future<String?> Function()? _jwtProvider;

  /// Creates a new instance using [MethodChannel] for communication.
  MethodChannelAltcraftCore() {
    AltcraftCorePlatformInterface.instance = this;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Handles calls initiated by the native side (e.g. JWT token requests).
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'getJwt':
        final provider = _jwtProvider;
        if (provider == null) return null;
        return provider();
    }
    return null;
  }

  // ---- Initialization ----

  @override
  Future<void> initialize(AltcraftConfig config) async {
    try {
      await _channel.invokeMethod('initialize', _coreConfigMap(config));
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'initialize failed');
    }
  }

  /// Serializes the core subset of the configuration.
  Map<String, dynamic> _coreConfigMap(AltcraftConfig config) {
    return {
      'apiUrl': config.apiUrl,
      if (config.rToken != null) 'rToken': config.rToken,
      if (config.appInfo != null) 'appInfo': config.appInfo!.toMap(),
      if (config.enableLogging != null) 'enableLogging': config.enableLogging,
      if (config.moduleConfigs.isNotEmpty)
        'moduleConfigs': config.moduleConfigs.map(
          (moduleId, moduleConfig) => MapEntry(
            moduleId,
            Map<String, dynamic>.from(moduleConfig),
          ),
        ),
    };
  }

  // ---- SDK Events ----

  @override
  Stream<SdkEvent> subscribeToEvents() {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map<SdkEvent>((
      dynamic event,
    ) {
      try {
        if (event is Map) {
          return SdkEvent.fromMap(Map<dynamic, dynamic>.from(event));
        }
        return SdkEvent(
          function: '',
          message: 'Invalid event received: $event',
          type: 'error',
        );
      } catch (e) {
        return SdkEvent(
          function: '',
          message: 'Failed to parse event: $e',
          type: 'error',
        );
      }
    });
    return _eventStream!;
  }

  @override
  Future<void> unsubscribeFromEvents() async {
    try {
      await _channel.invokeMethod('unsubscribeFromEvents');
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'unsubscribeFromEvents failed');
    }
  }

  // ---- State ----

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod('clear');
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'clear failed');
    }
  }

  // ---- Session (Android) ----

  @override
  Future<void> unlockInitialOperationsInThisSession() async {
    try {
      await _channel.invokeMethod('unlockInitialOperationsInThisSession');
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code,
          message: e.message ?? 'unlockInitialOperationsInThisSession failed');
    }
  }

  // ---- UserDefaults (iOS) ----

  @override
  Future<void> setUserDefaultsValue(
      String? suiteName, String key, String? value) async {
    try {
      await _channel.invokeMethod('setUserDefaultsValue', {
        'suiteName': suiteName,
        'key': key,
        'value': value,
      });
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'setUserDefaultsValue failed');
    }
  }

  @override
  Future<void> setAppGroup(String? groupName) async {
    try {
      await _channel.invokeMethod('setAppGroup', {'groupName': groupName});
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'setAppGroup failed');
    }
  }

  // ---- Authentication ----

  @override
  Future<void> setJwtProvider(Future<String?> Function() provider) async {
    try {
      _jwtProvider = provider;
      await _channel.invokeMethod('setJwtProvider');
    } on PlatformException catch (e) {
      _jwtProvider = null;
      throw AltcraftException(
          code: e.code, message: e.message ?? 'setJwtProvider failed');
    }
  }

  @override
  Future<void> authenticate() async {
    try {
      await _channel.invokeMethod('authenticate');
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'authenticate failed');
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await _channel.invokeMethod('logOut');
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'logOut failed');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAuthenticated');
      return result ?? false;
    } on PlatformException catch (e) {
      throw AltcraftException(
          code: e.code, message: e.message ?? 'isAuthenticated failed');
    }
  }
}
