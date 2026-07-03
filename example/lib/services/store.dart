import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:altcraft_sdk/src/models/category_data.dart';

// Pre-filled defaults (match RN example)
const kDefaultApiUrl = '';
const kDefaultJwt = '';
const kDefaultRToken = '';
const kMobileEventSid = '';
const kJwtKey = 'JWT_KEY';
const kAppGroupSuite = 'group.altcraft.flutter.app';

class ConfigData {
  final String apiUrl;
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

  // JWT
  Future<String> getJwtAnon() async {
    final prefs = await _getPrefs();
    return prefs.getString('jwt_anon') ?? kDefaultJwt;
  }

  Future<void> saveJwtAnon(String jwt) async {
    final prefs = await _getPrefs();
    await prefs.setString('jwt_anon', jwt);
  }

  Future<String> getJwtReg() async {
    final prefs = await _getPrefs();
    return prefs.getString('jwt_reg') ?? kDefaultJwt;
  }

  Future<void> saveJwtReg(String jwt) async {
    final prefs = await _getPrefs();
    await prefs.setString('jwt_reg', jwt);
  }

  Future<bool> getAuthStatus() async {
    final prefs = await _getPrefs();
    return prefs.getBool('auth_status') ?? false;
  }

  Future<void> saveAuthStatus(bool status) async {
    final prefs = await _getPrefs();
    await prefs.setBool('auth_status', status);
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
