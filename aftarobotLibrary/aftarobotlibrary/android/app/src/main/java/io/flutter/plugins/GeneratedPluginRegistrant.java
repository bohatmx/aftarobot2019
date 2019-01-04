package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import com.transistorsoft.flutter.backgroundfetch.BackgroundFetchPlugin;
import io.flutter.plugins.firebase.cloudfirestore.CloudFirestorePlugin;
import io.flutter.plugins.deviceinfo.DeviceInfoPlugin;
import io.flutter.plugins.firebaseauth.FirebaseAuthPlugin;
import io.flutter.plugins.firebase.core.FirebaseCorePlugin;
import io.flutter.plugins.firebase.database.FirebaseDatabasePlugin;
import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin;
import io.flutter.plugins.firebase.firebaseremoteconfig.FirebaseRemoteConfigPlugin;
import io.flutter.plugins.firebase.storage.FirebaseStoragePlugin;
import com.transistorsoft.flutter.backgroundgeolocation.FLTBackgroundGeolocationPlugin;
import com.pauldemarco.flutterblue.FlutterBluePlugin;
import com.sidlatau.flutterdocumentpicker.FlutterDocumentPickerPlugin;
import io.flutter.plugins.googlemaps.GoogleMapsPlugin;
import io.flutter.plugins.googlesignin.GoogleSignInPlugin;
import com.lyokone.location.LocationPlugin;
import io.flutter.plugins.pathprovider.PathProviderPlugin;
import com.baseflow.permissionhandler.PermissionHandlerPlugin;
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin;
import io.flutter.plugins.urllauncher.UrlLauncherPlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    BackgroundFetchPlugin.registerWith(registry.registrarFor("com.transistorsoft.flutter.backgroundfetch.BackgroundFetchPlugin"));
    CloudFirestorePlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.cloudfirestore.CloudFirestorePlugin"));
    DeviceInfoPlugin.registerWith(registry.registrarFor("io.flutter.plugins.deviceinfo.DeviceInfoPlugin"));
    FirebaseAuthPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebaseauth.FirebaseAuthPlugin"));
    FirebaseCorePlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.core.FirebaseCorePlugin"));
    FirebaseDatabasePlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.database.FirebaseDatabasePlugin"));
    FirebaseMessagingPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
    FirebaseRemoteConfigPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.firebaseremoteconfig.FirebaseRemoteConfigPlugin"));
    FirebaseStoragePlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.storage.FirebaseStoragePlugin"));
    FLTBackgroundGeolocationPlugin.registerWith(registry.registrarFor("com.transistorsoft.flutter.backgroundgeolocation.FLTBackgroundGeolocationPlugin"));
    FlutterBluePlugin.registerWith(registry.registrarFor("com.pauldemarco.flutterblue.FlutterBluePlugin"));
    FlutterDocumentPickerPlugin.registerWith(registry.registrarFor("com.sidlatau.flutterdocumentpicker.FlutterDocumentPickerPlugin"));
    GoogleMapsPlugin.registerWith(registry.registrarFor("io.flutter.plugins.googlemaps.GoogleMapsPlugin"));
    GoogleSignInPlugin.registerWith(registry.registrarFor("io.flutter.plugins.googlesignin.GoogleSignInPlugin"));
    LocationPlugin.registerWith(registry.registrarFor("com.lyokone.location.LocationPlugin"));
    PathProviderPlugin.registerWith(registry.registrarFor("io.flutter.plugins.pathprovider.PathProviderPlugin"));
    PermissionHandlerPlugin.registerWith(registry.registrarFor("com.baseflow.permissionhandler.PermissionHandlerPlugin"));
    SharedPreferencesPlugin.registerWith(registry.registrarFor("io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin"));
    UrlLauncherPlugin.registerWith(registry.registrarFor("io.flutter.plugins.urllauncher.UrlLauncherPlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
