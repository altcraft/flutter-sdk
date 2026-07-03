/// Configuration for initializing the Altcraft SDK.
class AltcraftConfig {
  /// API URL for the Altcraft backend.
  final String apiUrl;

  /// Optional RToken for authentication.
  final String? rToken;

  /// Optional application info (Firebase app ID, instance ID, version).
  final AppInfo? appInfo;

  /// Optional priority list of push providers.
  final List<String>? providerPriorityList;

  /// Optional flag to enable SDK logging.
  final bool? enableLogging;

  /// Android-only: notification icon resource ID.
  final int? icon;

  /// Android-only: push receiver modules.
  final List<String>? pushReceiverModules;

  /// Android-only: push channel name.
  final String? pushChannelName;

  /// Android-only: push channel description.
  final String? pushChannelDescription;

  const AltcraftConfig({
    required this.apiUrl,
    this.rToken,
    this.appInfo,
    this.providerPriorityList,
    this.enableLogging,
    this.icon,
    this.pushReceiverModules,
    this.pushChannelName,
    this.pushChannelDescription,
  });

  /// Converts config to a Map for MethodChannel serialization.
  Map<String, dynamic> toMap() {
    return {
      'apiUrl': apiUrl,
      if (rToken != null) 'rToken': rToken,
      if (appInfo != null) 'appInfo': appInfo!.toMap(),
      if (providerPriorityList != null) 'providerPriorityList': providerPriorityList,
      if (enableLogging != null) 'enableLogging': enableLogging,
      if (icon != null) 'android_icon': icon,
      if (pushReceiverModules != null) 'android_pushReceiverModules': pushReceiverModules,
      if (pushChannelName != null) 'android_pushChannelName': pushChannelName,
      if (pushChannelDescription != null) 'android_pushChannelDescription': pushChannelDescription,
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
