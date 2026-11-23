import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:altcraft_core/altcraft_core.dart';

// Pre-filled defaults (match AndroidModules example)
const String? kDefaultApiUrl = null;
const String? kDefaultJwtAnon = null;
const String? kDefaultJwtReg = null;
const kDefaultRToken = '';
const kMobileEventSid = '';
const kJwtKey = 'JWT_KEY';
const kAppGroupSuite = 'group.altcraft.flutter.app';

const kAppId = 'AltcraftMobile';
const kAppIid = '1.0.0';
const kAppVer = '1.0.0';

const kEmptyValueUi = '........';
const kExampleTitle = 'Altcraft';
const kExampleBody = 'Welcome to the Altcraft Notification Builder!';

const kFcmProvider = 'android-firebase';
const kHmsProvider = 'android-huawei';
const kRustoreProvider = 'android-rustore';
const kApnsProvider = 'ios-apns';

const kSubscribed = 'subscribed';
const kUnsubscribed = 'unsubscribed';
const kSuspended = 'suspended';

class ConfigData {
  final String? apiUrl;
  final String? rToken;
  final List<String> providerPriorityList;

  ConfigData({this.apiUrl = kDefaultApiUrl, this.rToken, this.providerPriorityList = const []});

  /// Returns the effective rToken: user-set value, or kDefaultRToken if non-empty, otherwise null.
  String? get effectiveRToken {
    if (rToken != null && rToken!.isNotEmpty) return rToken;
    return kDefaultRToken.isNotEmpty ? kDefaultRToken : null;
  }

  Map<String, dynamic> toJson() => {
        'apiUrl': apiUrl,
        'rToken': rToken,
        'providerPriorityList': providerPriorityList,
      };

  factory ConfigData.fromJson(Map<String, dynamic> json) => ConfigData(
        apiUrl: json['apiUrl'] as String? ?? kDefaultApiUrl,
        rToken: _parseRToken(json['rToken']),
        providerPriorityList: List<String>.from(json['providerPriorityList'] ?? []),
      );
}

/// Returns nullOrEmpty → null, otherwise trimmed value.
String? _parseRToken(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

class NotificationData {
  final String title;
  final String body;
  final String? smallImageUrl;
  final String? largeImageUrl;
  final List<String> buttons;

  const NotificationData({
    this.title = kExampleTitle,
    this.body = kExampleBody,
    this.smallImageUrl,
    this.largeImageUrl,
    this.buttons = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'smallImageUrl': smallImageUrl,
        'largeImageUrl': largeImageUrl,
        'buttons': buttons,
      };

  factory NotificationData.fromJson(Map<String, dynamic> json) => NotificationData(
        title: json['title'] as String? ?? kExampleTitle,
        body: json['body'] as String? ?? kExampleBody,
        smallImageUrl: json['smallImageUrl'] as String?,
        largeImageUrl: json['largeImageUrl'] as String?,
        buttons: List<String>.from(json['buttons'] ?? []),
      );
}

class Store {
  Store._();

  static final Store instance = Store._();

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  // Config
  Future<ConfigData> getConfig() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('config') ?? '{}';
    return ConfigData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveConfig(ConfigData config) async {
    final prefs = await _getPrefs();
    await prefs.setString('config', jsonEncode(config.toJson()));
  }

  // Token
  Future<void> saveTokenData(String provider, String token) async {
    final prefs = await _getPrefs();
    await prefs.setString('token_provider', provider);
    await prefs.setString('token_value', token);
  }

  Future<String> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString('token_value') ?? '';
  }

  Future<String> getProvider() async {
    final prefs = await _getPrefs();
    return prefs.getString('token_provider') ?? '';
  }

  Future<String?> getTokenUpdateTime() async {
    final prefs = await _getPrefs();
    return prefs.getString('token_update_time');
  }

  Future<void> saveTokenUpdateTime(String time) async {
    final prefs = await _getPrefs();
    await prefs.setString('token_update_time', time);
  }

  // JWT
  Future<String?> getJwtAnon() async {
    final prefs = await _getPrefs();
    return prefs.getString('jwt_anon') ?? kDefaultJwtAnon;
  }

  Future<void> saveJwtAnon(String jwt) async {
    final prefs = await _getPrefs();
    await prefs.setString('jwt_anon', jwt);
  }

  Future<String?> getJwtReg() async {
    final prefs = await _getPrefs();
    return prefs.getString('jwt_reg') ?? kDefaultJwtReg;
  }

  Future<void> saveJwtReg(String jwt) async {
    final prefs = await _getPrefs();
    await prefs.setString('jwt_reg', jwt);
  }

  Future<void> removeJwts() async {
    final prefs = await _getPrefs();
    await prefs.remove('jwt_anon');
    await prefs.remove('jwt_reg');
  }

  Future<bool> getAuthStatus() async {
    final prefs = await _getPrefs();
    return prefs.getBool('auth_status') ?? false;
  }

  Future<void> saveAuthStatus(bool status) async {
    final prefs = await _getPrefs();
    await prefs.setBool('auth_status', status);
  }

  Future<bool> getExternalAuthStatus() async {
    final prefs = await _getPrefs();
    return prefs.getBool('external_auth_status') ?? false;
  }

  Future<void> saveExternalAuthStatus(bool status) async {
    final prefs = await _getPrefs();
    await prefs.setBool('external_auth_status', status);
  }

  // Subscription statuses
  Future<String> getAppStatus() async {
    final prefs = await _getPrefs();
    return prefs.getString('app_status') ?? kUnsubscribed;
  }

  Future<void> saveAppStatus(String status) async {
    final prefs = await _getPrefs();
    await prefs.setString('app_status', status);
  }

  Future<String> getInAppStatus() async {
    final prefs = await _getPrefs();
    return prefs.getString('inapp_status') ?? kUnsubscribed;
  }

  Future<void> saveInAppStatus(String status) async {
    final prefs = await _getPrefs();
    await prefs.setString('inapp_status', status);
  }

  // Subscribe settings
  Future<SubscribeSettings> getSubscribeSettings() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('subscribe_settings') ?? '{}';
    return SubscribeSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveSubscribeSettings(SubscribeSettings settings) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      'subscribe_settings',
      jsonEncode(settings.toJson()),
    );
  }

  // Notification data (Example screen)
  Future<NotificationData> getNotificationData() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('notification_data') ?? '{}';
    return NotificationData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveNotificationData(NotificationData data) async {
    final prefs = await _getPrefs();
    await prefs.setString('notification_data', jsonEncode(data.toJson()));
  }

  // Clear
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}

class SubscribeSettings {
  final bool sync;
  final bool replace;
  final bool skipTriggers;
  final Map<String, String> customFields;
  final Map<String, String> profileFields;
  final List<CategoryData> cats;

  const SubscribeSettings({
    this.sync = true,
    this.replace = false,
    this.skipTriggers = false,
    this.customFields = const {},
    this.profileFields = const {},
    this.cats = const [],
  });

  Map<String, dynamic> toJson() => {
        'sync': sync,
        'replace': replace,
        'skipTriggers': skipTriggers,
        'customFields': customFields,
        'profileFields': profileFields,
        'cats': cats.map((c) => c.toJson()).toList(),
      };

  factory SubscribeSettings.fromJson(Map<String, dynamic> json) => SubscribeSettings(
        sync: json['sync'] as bool? ?? true,
        replace: json['replace'] as bool? ?? false,
        skipTriggers: json['skipTriggers'] as bool? ?? false,
        customFields: Map<String, String>.from(json['customFields'] ?? {}),
        profileFields: Map<String, String>.from(json['profileFields'] ?? {}),
        cats: (json['cats'] as List?)?.map((c) => CategoryData.fromJson(c as Map<String, dynamic>)).toList() ?? [],
      );
}
