import 'package:altcraft_core/altcraft_core.dart';

/// Push module configuration passed to the SDK builder.
///
/// Mirrors the native push configuration extension. On Android, the icon,
/// receiver modules, and notification channel options are applied; iOS uses
/// only [providerPriority].
class PushConfig {
  /// Push provider identifiers ordered by priority.
  final List<String>? providerPriority;

  /// Android-only: notification icon resource ID.
  ///
  /// Takes precedence over [iconName] when both are provided.
  final int? icon;

  /// Android-only: notification icon resource name resolved via
  /// `getIdentifier` (`drawable` by default, falling back to `mipmap`).
  final String? iconName;

  /// Android-only: package name prefixes containing push receiver
  /// implementations.
  final List<String>? pushReceiverModules;

  /// Android-only: custom notification channel name.
  final String? pushChannelName;

  /// Android-only: custom notification channel description.
  final String? pushChannelDescription;

  const PushConfig({
    this.providerPriority,
    this.icon,
    this.iconName,
    this.pushReceiverModules,
    this.pushChannelName,
    this.pushChannelDescription,
  });

  /// Converts the configuration into a method-channel-safe map.
  Map<String, dynamic> toMap() {
    return {
      if (providerPriority != null) 'providerPriority': providerPriority,
      if (icon != null) 'icon': icon,
      if (iconName != null) 'iconName': iconName,
      if (pushReceiverModules != null)
        'pushReceiverModules': pushReceiverModules,
      if (pushChannelName != null) 'pushChannelName': pushChannelName,
      if (pushChannelDescription != null)
        'pushChannelDescription': pushChannelDescription,
    };
  }
}

/// Adds the push module configuration to an [AltcraftConfigBuilder].
///
/// Available when `package:altcraft_push/altcraft_push.dart` is imported,
/// mirroring native module linking. The core module knows nothing about push:
/// the configuration is forwarded as a generic module entry at initialization.
extension PushConfigBuilderExtension on AltcraftConfigBuilder {
  /// Adds the push module configuration.
  AltcraftConfigBuilder pushConfig(PushConfig config) {
    return addModuleConfiguration('push', config.toMap());
  }
}
