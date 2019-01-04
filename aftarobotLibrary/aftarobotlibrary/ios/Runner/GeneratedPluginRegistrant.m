//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"
#import <background_fetch/BackgroundFetchPlugin.h>
#import <cloud_firestore/CloudFirestorePlugin.h>
#import <device_info/DeviceInfoPlugin.h>
#import <firebase_auth/FirebaseAuthPlugin.h>
#import <firebase_core/FirebaseCorePlugin.h>
#import <firebase_database/FirebaseDatabasePlugin.h>
#import <firebase_messaging/FirebaseMessagingPlugin.h>
#import <firebase_remote_config/FirebaseRemoteConfigPlugin.h>
#import <firebase_storage/FirebaseStoragePlugin.h>
#import <flutter_background_geolocation/FLTBackgroundGeolocationPlugin.h>
#import <flutter_blue/FlutterBluePlugin.h>
#import <flutter_document_picker/FlutterDocumentPickerPlugin.h>
#import <google_maps_flutter/GoogleMapsPlugin.h>
#import <google_sign_in/GoogleSignInPlugin.h>
#import <location/LocationPlugin.h>
#import <path_provider/PathProviderPlugin.h>
#import <permission_handler/PermissionHandlerPlugin.h>
#import <shared_preferences/SharedPreferencesPlugin.h>
#import <url_launcher/UrlLauncherPlugin.h>

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [BackgroundFetchPlugin registerWithRegistrar:[registry registrarForPlugin:@"BackgroundFetchPlugin"]];
  [FLTCloudFirestorePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTCloudFirestorePlugin"]];
  [FLTDeviceInfoPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTDeviceInfoPlugin"]];
  [FLTFirebaseAuthPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseAuthPlugin"]];
  [FLTFirebaseCorePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseCorePlugin"]];
  [FLTFirebaseDatabasePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseDatabasePlugin"]];
  [FLTFirebaseMessagingPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseMessagingPlugin"]];
  [FirebaseRemoteConfigPlugin registerWithRegistrar:[registry registrarForPlugin:@"FirebaseRemoteConfigPlugin"]];
  [FLTFirebaseStoragePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseStoragePlugin"]];
  [FLTBackgroundGeolocationPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTBackgroundGeolocationPlugin"]];
  [FlutterBluePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBluePlugin"]];
  [FlutterDocumentPickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterDocumentPickerPlugin"]];
  [FLTGoogleMapsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTGoogleMapsPlugin"]];
  [FLTGoogleSignInPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTGoogleSignInPlugin"]];
  [LocationPlugin registerWithRegistrar:[registry registrarForPlugin:@"LocationPlugin"]];
  [FLTPathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPathProviderPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [FLTSharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTSharedPreferencesPlugin"]];
  [FLTUrlLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTUrlLauncherPlugin"]];
}

@end
