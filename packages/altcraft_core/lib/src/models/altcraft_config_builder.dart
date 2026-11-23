import 'altcraft_config.dart';

/// Builder for [AltcraftConfig].
///
/// Mirrors the native `AltcraftConfiguration.Builder`: core parameters are set
/// in the constructor, while module configurations are added through
/// extension methods provided by module packages.
///
/// ```dart
/// import 'package:altcraft_core/altcraft_core.dart';
/// import 'package:altcraft_inapp/altcraft_inapp.dart';
/// import 'package:altcraft_push/altcraft_push.dart';
///
/// await AltcraftCore.initialize(
///   AltcraftConfigBuilder(apiUrl: 'https://your-api.altcraft.com')
///       .pushConfig(const PushConfig(providerPriority: ['android-firebase']))
///       .inAppConfig(const InAppConfig(maxPlacements: 50))
///       .build(),
/// );
/// ```
///
/// Extension methods are visible only when the corresponding module package
/// is imported, mirroring native module linking. The core module knows nothing
/// about concrete modules: it only forwards the generic [AltcraftConfig.moduleConfigs]
/// map to the native SDK.
class AltcraftConfigBuilder {
  /// API URL for the Altcraft backend.
  final String apiUrl;

  /// Optional RToken for authentication.
  final String? rToken;

  /// Optional application info (Firebase app ID, instance ID, version).
  final AppInfo? appInfo;

  /// Optional flag to enable SDK logging.
  final bool? enableLogging;

  final Map<String, Map<String, dynamic>> _moduleConfigs = {};

  AltcraftConfigBuilder({
    required this.apiUrl,
    this.rToken,
    this.appInfo,
    this.enableLogging,
  });

  /// Adds a module configuration under [moduleId].
  ///
  /// Intended to be called by module extensions; a later call for the same
  /// [moduleId] replaces the previous configuration.
  AltcraftConfigBuilder addModuleConfiguration(
    String moduleId,
    Map<String, dynamic> config,
  ) {
    _moduleConfigs[moduleId] = Map<String, dynamic>.unmodifiable(config);
    return this;
  }

  /// Builds an immutable [AltcraftConfig].
  AltcraftConfig build() {
    return AltcraftConfig(
      apiUrl: apiUrl,
      rToken: rToken,
      appInfo: appInfo,
      enableLogging: enableLogging,
      moduleConfigs: Map<String, Map<String, dynamic>>.unmodifiable(
        _moduleConfigs.map(
          (moduleId, config) => MapEntry(
            moduleId,
            Map<String, dynamic>.unmodifiable(config),
          ),
        ),
      ),
    );
  }
}
