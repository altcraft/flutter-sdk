/// Method and event channel names used by the Altcraft Flutter SDK modules.
///
/// Each SDK module communicates over its own method channel. The umbrella
/// [sdk] channel handles full SDK initialization. Core also exposes a shared
/// [events] channel for native SDK events.
abstract final class AltcraftChannels {
  /// Umbrella channel: full SDK initialization (push/in-app options included).
  static const String sdk = 'com.altcraft/sdk';

  /// Core module channel: initialization, events, authentication, storage.
  static const String core = 'com.altcraft/core';

  /// Push module channel.
  static const String push = 'com.altcraft/push';

  /// In-App module channel.
  static const String inApp = 'com.altcraft/inapp';

  /// Target module channel.
  static const String target = 'com.altcraft/target';

  /// Profile module channel.
  static const String profile = 'com.altcraft/profile';

  /// Shared native SDK events channel (owned by the core module).
  static const String events = 'com.altcraft/events';
}
