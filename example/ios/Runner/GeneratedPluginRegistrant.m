//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<altcraft_core/AltcraftCorePlugin.h>)
#import <altcraft_core/AltcraftCorePlugin.h>
#else
@import altcraft_core;
#endif

#if __has_include(<altcraft_inapp/AltcraftInAppPlugin.h>)
#import <altcraft_inapp/AltcraftInAppPlugin.h>
#else
@import altcraft_inapp;
#endif

#if __has_include(<altcraft_profile/AltcraftProfilePlugin.h>)
#import <altcraft_profile/AltcraftProfilePlugin.h>
#else
@import altcraft_profile;
#endif

#if __has_include(<altcraft_push/AltcraftPushPlugin.h>)
#import <altcraft_push/AltcraftPushPlugin.h>
#else
@import altcraft_push;
#endif

#if __has_include(<altcraft_target/AltcraftTargetPlugin.h>)
#import <altcraft_target/AltcraftTargetPlugin.h>
#else
@import altcraft_target;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [AltcraftCorePlugin registerWithRegistrar:[registry registrarForPlugin:@"AltcraftCorePlugin"]];
  [AltcraftInAppPlugin registerWithRegistrar:[registry registrarForPlugin:@"AltcraftInAppPlugin"]];
  [AltcraftProfilePlugin registerWithRegistrar:[registry registrarForPlugin:@"AltcraftProfilePlugin"]];
  [AltcraftPushPlugin registerWithRegistrar:[registry registrarForPlugin:@"AltcraftPushPlugin"]];
  [AltcraftTargetPlugin registerWithRegistrar:[registry registrarForPlugin:@"AltcraftTargetPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
}

@end
