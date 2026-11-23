import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:altcraft_push/altcraft_push.dart';
import 'package:altcraft_sdk_example/services/event_bus.dart';
import 'package:altcraft_sdk_example/services/store.dart';

/// Central observable app state — mirrors AndroidModules MainViewModel.
/// Subscribes to SDK events and updates statuses, token, placement count.
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  StreamSubscription<SdkEvent>? _subscription;
  final List<SdkEvent> _queue = [];
  bool _draining = false;

  String status = kUnsubscribed;
  String inAppStatus = kUnsubscribed;
  bool authStatus = false;
  String? token;
  String? provider;
  String? tokenUpdateTime;
  int placementCount = 0;
  final List<SdkEvent> events = [];

  Future<void> init() async {
    if (_subscription != null) return;
    _subscription = EventBus.instance.stream.listen((ev) async {
      _queue.add(ev);
      await _drainQueue();
    });

    final store = Store.instance;
    status = await store.getAppStatus();
    inAppStatus = await store.getInAppStatus();
    authStatus = await store.getAuthStatus();
    token = await store.getToken();
    provider = await store.getProvider();
    if (token!.isEmpty) token = null;
    if (provider!.isEmpty) provider = null;
    tokenUpdateTime = await store.getTokenUpdateTime();
    notifyListeners();
  }

  Future<void> syncAuthFromSdk() async {
    try {
      final sdkAuth = await AltcraftCore.isAuthenticated();
      if (sdkAuth != authStatus) {
        authStatus = sdkAuth;
        await Store.instance.saveAuthStatus(sdkAuth);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> reloadFromStore() async {
    final store = Store.instance;
    status = await store.getAppStatus();
    inAppStatus = await store.getInAppStatus();
    authStatus = await store.getAuthStatus();
    notifyListeners();
  }

  Future<void> updateTokenUi() async {
    try {
      final tokenData = await AltcraftPush.getPushToken();
      if (tokenData != null) {
        token = tokenData.token;
        provider = tokenData.provider;
        await Store.instance.saveTokenData(tokenData.provider, tokenData.token);
      } else {
        token = null;
        provider = null;
      }
      tokenUpdateTime ??= await Store.instance.getTokenUpdateTime();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> handleCleared() async {
    token = null;
    provider = null;
    status = kUnsubscribed;
    inAppStatus = kUnsubscribed;
    authStatus = false;
    tokenUpdateTime = null;
    await Store.instance.saveAppStatus(kUnsubscribed);
    await Store.instance.saveInAppStatus(kUnsubscribed);
    await Store.instance.saveAuthStatus(false);
    notifyListeners();
  }

  void clearEvents() {
    events.clear();
    notifyListeners();
  }

  /// Adds JSON content received from a JSON-content in-app campaign.
  ///
  /// The payload is appended to the events list so it is visible on the
  /// Logs screen.
  void addJsonContent(String json) {
    events.add(SdkEvent(
      function: 'inapp/json_content',
      message: json,
      type: 'json',
    ));
    if (events.length > 200) events.removeRange(0, events.length - 200);
    notifyListeners();
  }

  Future<void> _drainQueue() async {
    if (_draining) return;
    _draining = true;
    while (_queue.isNotEmpty) {
      final ev = _queue.removeAt(0);
      try {
        await _handleEvent(ev);
      } catch (e) {
        debugPrint('Event handling error: $e');
      }
    }
    _draining = false;
  }

  Future<void> _handleEvent(SdkEvent ev) async {
    events.add(ev);
    if (events.length > 200) events.removeRange(0, events.length - 200);

    final msg = ev.message;
    final value = ev.value;
    final store = Store.instance;

    // Push subscription status events
    if (msg.contains('successful request: push/subscribe') ||
        msg.contains('successful request: push/suspend') ||
        msg.contains('successful request: push/unsubscribe') ||
        msg.contains('successful request: push/status')) {
      status = _subscriptionStatusFrom(value) ?? kUnsubscribed;
      await store.saveAppStatus(status);
    } else if (msg.contains('failed request: push/status')) {
      if (_errorTextFrom(value)?.contains('profile not found') == true ||
          ev.code == 404) {
        status = kUnsubscribed;
        await store.saveAppStatus(status);
      }
    } else if (msg.contains('successful request: push/update')) {
      final sub = _subscriptionFrom(value);
      if (sub != null) {
        token = sub['subscriptionId']?.toString();
        provider = sub['provider']?.toString();
        if (token != null && provider != null) {
          await store.saveTokenData(provider!, token!);
        }
      }
      tokenUpdateTime = ev.timestamp;
      if (tokenUpdateTime != null) {
        await store.saveTokenUpdateTime(tokenUpdateTime!);
      }
    } else if (msg.contains('push provider set')) {
      tokenUpdateTime = ev.timestamp;
      if (tokenUpdateTime != null) {
        await store.saveTokenUpdateTime(tokenUpdateTime!);
      }
      await updateTokenUi();
    } else if (msg == 'SDK configuration is installed') {
      await updateTokenUi();
      status = await store.getAppStatus();
    } else if (msg == 'SDK data has been cleared') {
      await handleCleared();
    } else if (msg.contains('successful request: profile/authenticate')) {
      authStatus = true;
      await store.saveAuthStatus(true);
    } else if (msg.contains('User logged out') ||
        msg.contains('User is not authenticated')) {
      authStatus = false;
      await store.saveAuthStatus(false);
    } else if (msg.contains('successful request: inapp/subscribe')) {
      inAppStatus = kSubscribed;
      await store.saveInAppStatus(inAppStatus);
    } else if (msg.contains('successful request: inapp/unsubscribe')) {
      inAppStatus = kUnsubscribed;
      await store.saveInAppStatus(inAppStatus);
    } else if (msg.contains('successful request: inapp/status')) {
      final sub = _subscriptionFrom(value);
      inAppStatus = sub?['status']?.toString() ?? kUnsubscribed;
      await store.saveInAppStatus(inAppStatus);
    } else if (msg.contains('successful request: inapp/placements')) {
      final smids = value?['all_smid'];
      placementCount = smids is List ? smids.length : 0;
    }

    notifyListeners();
  }

  Map<String, dynamic>? _subscriptionFrom(dynamic value) {
    if (value is! Map) return null;
    final profile = value['profile'];
    if (profile is! Map) return null;
    final sub = profile['subscription'];
    if (sub is! Map) return null;
    return Map<String, dynamic>.from(sub);
  }

  String? _subscriptionStatusFrom(dynamic value) =>
      _subscriptionFrom(value)?['status']?.toString();

  String? _errorTextFrom(dynamic value) {
    if (value is! Map) return null;
    final v = value['response_with_http_code']?.toString() ?? value.toString();
    return v;
  }
}
