import 'package:altcraft_core/altcraft_core.dart';

/// In-App module configuration passed to the SDK builder.
///
/// Mirrors the native in-app configuration extension. Values match the native
/// defaults when not specified.
class InAppConfig {
  /// Enables automatic requests of In-App placements.
  final bool inAppAutoRequest;

  /// Interval between automatic placement requests.
  ///
  /// The native SDKs accept a minimum of 15 minutes; lower values are clamped
  /// on the native side.
  final Duration placementsRequestInterval;

  /// Maximum number of placements kept in local storage.
  final int maxPlacements;

  const InAppConfig({
    this.inAppAutoRequest = true,
    this.placementsRequestInterval = const Duration(minutes: 30),
    this.maxPlacements = 500,
  });

  /// Converts the configuration into a method-channel-safe map.
  Map<String, dynamic> toMap() {
    return {
      'inAppAutoRequest': inAppAutoRequest,
      'placementsRequestIntervalMs': placementsRequestInterval.inMilliseconds,
      'maxPlacements': maxPlacements,
    };
  }
}

/// Adds the In-App module configuration to an [AltcraftConfigBuilder].
///
/// Available when `package:altcraft_inapp/altcraft_inapp.dart` is imported,
/// mirroring native module linking. The core module knows nothing about in-app:
/// the configuration is forwarded as a generic module entry at initialization.
extension InAppConfigBuilderExtension on AltcraftConfigBuilder {
  /// Adds the In-App module configuration.
  AltcraftConfigBuilder inAppConfig(InAppConfig config) {
    return addModuleConfiguration('inapp', config.toMap());
  }
}
