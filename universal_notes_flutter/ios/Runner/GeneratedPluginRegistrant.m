//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_downloader/FlutterDownloaderPlugin.h>)
#import <flutter_downloader/FlutterDownloaderPlugin.h>
#else
@import flutter_downloader;
#endif

#if __has_include(<flutter_keyboard_visibility_temp_fork/FlutterKeyboardVisibilityTempForkPlugin.h>)
#import <flutter_keyboard_visibility_temp_fork/FlutterKeyboardVisibilityTempForkPlugin.h>
#else
@import flutter_keyboard_visibility_temp_fork;
#endif

#if __has_include(<open_file_ios/OpenFilePlugin.h>)
#import <open_file_ios/OpenFilePlugin.h>
#else
@import open_file_ios;
#endif

#if __has_include(<package_info_plus/FPPPackageInfoPlusPlugin.h>)
#import <package_info_plus/FPPPackageInfoPlusPlugin.h>
#else
@import package_info_plus;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<quill_native_bridge_ios/QuillNativeBridgePlugin.h>)
#import <quill_native_bridge_ios/QuillNativeBridgePlugin.h>
#else
@import quill_native_bridge_ios;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterDownloaderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterDownloaderPlugin"]];
  [FlutterKeyboardVisibilityTempForkPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterKeyboardVisibilityTempForkPlugin"]];
  [OpenFilePlugin registerWithRegistrar:[registry registrarForPlugin:@"OpenFilePlugin"]];
  [FPPPackageInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPPackageInfoPlusPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [QuillNativeBridgePlugin registerWithRegistrar:[registry registrarForPlugin:@"QuillNativeBridgePlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
}

@end
