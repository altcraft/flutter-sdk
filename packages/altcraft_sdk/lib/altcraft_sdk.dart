/// Altcraft SDK for Flutter.
///
/// Umbrella package for the Altcraft push notification platform. Provides the
/// full `AltcraftSDK` API and complete SDK initialization with the options of
/// the connected modules, for Android and iOS.
///
/// For modular usage, depend on the individual module packages instead:
/// `altcraft_core`, `altcraft_push`, `altcraft_inapp`, `altcraft_target`,
/// `altcraft_profile`.
library;

export 'package:altcraft_core/altcraft_core.dart';
export 'package:altcraft_push/altcraft_push.dart';
export 'package:altcraft_inapp/altcraft_inapp.dart';
export 'package:altcraft_target/altcraft_target.dart';
export 'package:altcraft_profile/altcraft_profile.dart';
export 'src/altcraft_sdk.dart';
export 'src/altcraft_sdk_method_channel.dart';
export 'src/altcraft_sdk_platform_interface.dart';
