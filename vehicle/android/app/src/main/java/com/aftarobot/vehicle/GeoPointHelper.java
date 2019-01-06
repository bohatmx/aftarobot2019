package com.aftarobot.vehicle;

import android.support.annotation.NonNull;
import android.util.Log;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.GeoPoint;
import com.google.firebase.firestore.QueryDocumentSnapshot;
import com.google.firebase.firestore.QuerySnapshot;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import org.imperiumlabs.geofirestore.GeoFirestore;
import org.imperiumlabs.geofirestore.GeoQuery;
import org.imperiumlabs.geofirestore.GeoQueryEventListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;

import io.flutter.plugin.common.EventChannel;

public class GeoPointHelper {
    private static FirebaseFirestore fs = FirebaseFirestore.getInstance();

    static void findLandmarksWithin(final double latitude,
                                    final double longitude,
                                    final double radius,
                                    final GeoPointListener listener) {

        Log.d(TAG, "findLandmarksWithin: ***  ℹ️ setting up GeoFirestore for geo query  ℹ️");
        CollectionReference geoFirestoreRef = fs.collection("geoQueryLocations");
        final GeoFirestore geoFirestore = new GeoFirestore(geoFirestoreRef);

        searchGeoPoints(latitude, longitude, radius, listener, geoFirestore);


    }

    private static void searchGeoPoints(double latitude,
                                        double longitude,
                                        double radius,
                                        final GeoPointListener listener, GeoFirestore geoFirestore) {
        Log.d(TAG, "\n\n---- ****** searchGeoPoints: \uD83D\uDCCD \uD83D\uDCCD starting geo search ...............");

        final HashMap<String, GeoPoint> map = new HashMap<>();
        GeoQuery geoQuery = geoFirestore.queryAtLocation(new GeoPoint(latitude, longitude), radius);
        Log.d(TAG, "\uD83D\uDCCD \uD83D\uDCCD findLandmarksWithin radius: "+radius+" km. ... adding addGeoQueryDataEventListener");

        geoQuery.addGeoQueryEventListener(new GeoQueryEventListener() {
            @Override
            public void onKeyEntered(String s, GeoPoint geoPoint) {
                map.put(s, geoPoint);
                Log.d(TAG, "onKeyEntered: \uD83D\uDD35 :: geoPoint found .... adding to hash map: " + map.size()
                + " geoPoint: " + new Gson().toJson(geoPoint));
            }

            @Override
            public void onKeyExited(String s) {

            }

            @Override
            public void onKeyMoved(String s, GeoPoint geoPoint) {

            }

            @Override
            public void onGeoQueryReady() {
                Log.d(TAG, "onGeoQueryReady:   ✅ - ready to deliver IDs for getting landmarks: " + map.size());
                List<HashMap<String,String>> list = new ArrayList<>();
                for (String key: map.keySet()) {
                    HashMap<String,String> mapx = new HashMap<>();
                    mapx.put(key, G.toJson(map.get(key)));
                    list.add(mapx);
                }
                Log.d(TAG, "onGeoQueryReady:   ✅ - returning " + list.size() + " geoPoints");
                listener.onGeoPointsFound(list);
            }

            @Override
            public void onGeoQueryError(Exception e) {
                Log.e(TAG, "onGeoQueryError:  \uD83D\uDCCD  \uD83D\uDCCD  \uD83D\uDCCD Sir, Sir can I please have some more? ", e);
            }
        });
    }
    public static final Gson G = new GsonBuilder().setPrettyPrinting().create();

    private static final String TAG = GeoPointHelper.class.getSimpleName();

}


