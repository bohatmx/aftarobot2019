package com.aftarobot.migrator4;

import android.os.Bundle;
import android.util.Log;

import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.GeoPoint;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import org.imperiumlabs.geofirestore.GeoFirestore;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String ADD_GEO_QUERY_LOCATION_CHANNEL = "aftarobot/addGeoQueryLocation";
    MethodChannel.Result mResult;
    public static final String TAG = "MigratorWildSide";
    public static final Gson G = new GsonBuilder().setPrettyPrinting().create();
    @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    Log.d(TAG, "\n\n onCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up ADD_GEO_QUERY_LOCATION_CHANNELl");
    new MethodChannel(getFlutterView(), ADD_GEO_QUERY_LOCATION_CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                mResult = result;
                Object args = call.arguments;
                Log.d(TAG, "\uD83D\uDCCD\uD83D\uDCCD ****************** ADD_GEO_QUERY_LOCATION_CHANNEL onMethodCall: arguments: \n" + args.toString());

                if (call.method.equalsIgnoreCase("addGeoQueryLocation")) {
                  String json = args.toString();
                  LandmarkDTO landmark = G.fromJson(json, LandmarkDTO.class);
                  addQueryLocation(landmark);
                } else {
                  mResult.error("Method not feelin right  ⚠️", "Error", "Like, Fucked!");
                }
              }
            });

  }

  static FirebaseFirestore fs = FirebaseFirestore.getInstance();
  //todo - this code belongs in the migrator AND routebuilder apps ------- FIX!!
   void addQueryLocation(final LandmarkDTO landmark) {
    CollectionReference geoQueryLocationsRef = fs.collection("geoQueryLocations");
    final GeoFirestore geoFirestore = new GeoFirestore(geoQueryLocationsRef);
      String landmarkID = landmark.getLandmarkID();
      geoFirestore.setLocation(landmarkID, new GeoPoint(landmark.getLatitude(), landmark.getLongitude()), new GeoFirestore.CompletionListener() {
          @Override
          public void onComplete(Exception exception) {
              if (exception == null) {
                  Log.d(TAG,"✅ Location saved for :: " + landmark.getLandmarkName() + " on server successfully!");
                  mResult.success("✅ ✅ ✅ Geo Query Location created for " + landmark.getLandmarkName());
              } else {
                  Log.e(TAG, "onComplete:  ⚠️  ⚠️  ⚠️ WE HAVE A PROBLEM, Senor!" );
              }
          }
      });
  }
}
