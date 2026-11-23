/// Configuration for initializing the Altcraft SDK.
///
/// Contains core parameters plus a generic map of module configurations.
/// Module packages contribute their own entries through builder extensions
/// (for example `pushConfig` from `altcraft_push`), so this class does not
/// depend on any specific module.
class AltcraftConfig {
  /// API URL for the Altcraft backend.
  final String apiUrl;

  /// Optional RToken for authentication.
  final String? rToken;

  /// Optional application info (Firebase app ID, instance ID, version).
  final AppInfo? appInfo;

  /// Optional flag to enable SDK logging.
  final bool? enableLogging;

  /// Module configurations keyed by module identifier.
  ///
  /// Filled by module builder extensions; the core module forwards this map
  /// to the native SDK initialization without interpreting its contents.
  final Map<String, Map<String, dynamic>> moduleConfigs;

  const AltcraftConfig({
    required this.apiUrl,
    this.rToken,
    this.appInfo,
    this.enableLogging,
    this.moduleConfigs = const {},
  });

  /// Converts config to a Map for MethodChannel serialization.
  Map<String, dynamic> toMap() {
    return {
      'apiUrl': apiUrl,
      if (rToken != null) 'rToken': rToken,
      if (appInfo != null) 'appInfo': appInfo!.toMap(),
      if (enableLogging != null) 'enableLogging': enableLogging,
      if (moduleConfigs.isNotEmpty)
        'moduleConfigs': moduleConfigs.map(
          (moduleId, config) => MapEntry(
            moduleId,
            Map<String, dynamic>.from(config),
          ),
        ),
    };
  }
}

/// Application info for Firebase/FCM integration.
class AppInfo {
  final String appID;
  final String appIID;
  final String appVer;

  const AppInfo({
    required this.appID,
    required this.appIID,
    required this.appVer,
  });

  Map<String, dynamic> toMap() {
    return {
      'appID': appID,
      'appIID': appIID,
      'appVer': appVer,
    };
  }
}
