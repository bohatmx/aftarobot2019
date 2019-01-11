package com.aftarobot.commuter.util;

import android.util.Log;

import com.aftarobot.commuter.log.LogFileWriter;
import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.GeoPoint;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import org.imperiumlabs.geofirestore.GeoFirestore;
import org.imperiumlabs.geofirestore.GeoQuery;
import org.imperiumlabs.geofirestore.GeoQueryEventListener;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

public class GeoPointHelper {
    private static final String TAG = GeoPointHelper.class.getSimpleName();
    public static void writeVehicleLocation(String vehiclePath, double latitude, double longitude, final AddVehicleLocationListener listener) {
        LogFileWriter.print(TAG, "‼️ writeVehicleLocation: ***  ℹ️ vehiclePath: " + vehiclePath);
        FirebaseFirestore fs = FirebaseFirestore.getInstance();

        CollectionReference geoFirestoreRef = fs.collection("geoVehicleLocations");
        final GeoFirestore geoFirestore = new GeoFirestore(geoFirestoreRef);

        String time = "" + new Date().getTime();
        String newPath = vehiclePath.replace("/", "@");
        String modifiedPath = time + "@" + newPath;
        LogFileWriter.print(TAG, "‼️  vehiclePath incoming: "+vehiclePath+" :::  modifiedPath for vehicle: " + modifiedPath);
        GeoPoint point = new GeoPoint(latitude, longitude);
        geoFirestore.setLocation(modifiedPath, point, new GeoFirestore.CompletionListener() {
            @Override
            public void onComplete(Exception e) {
                if (e == null) {
                    listener.onVehicleLocationAdded();
                } else {
                    listener.onError("‼️‼️" + e.getMessage());
                }
            }
        });

    }
    public static void findLandmarksWithin(final double latitude,
                                    final double longitude,
                                    final double radius,
                                    final LandmarkGeoPointListener listener) {

        LogFileWriter.print(TAG, "findLandmarksWithin: ***  ℹ️ setting up GeoFirestore for geo query  ℹ️");
        FirebaseFirestore fs = FirebaseFirestore.getInstance();

        CollectionReference geoFirestoreRef = fs.collection("geoQueryLocations");
        final GeoFirestore geoFirestore = new GeoFirestore(geoFirestoreRef);

        searchGeoPoints(latitude, longitude, radius, listener, geoFirestore);


    }

    private static void searchGeoPoints(double latitude,
                                        double longitude,
                                        double radius,
                                        final LandmarkGeoPointListener listener, GeoFirestore geoFirestore) {
        LogFileWriter.print(TAG, "\n\n---- ****** searchGeoPoints: \uD83D\uDCCD \uD83D\uDCCD starting geo search ...............");

        final HashMap<String, GeoPoint> map = new HashMap<>();
        GeoQuery geoQuery = geoFirestore.queryAtLocation(new GeoPoint(latitude, longitude), radius);
        LogFileWriter.print(TAG, "\uD83D\uDCCD \uD83D\uDCCD findLandmarksWithin radius: "+radius+" km. ... adding addGeoQueryDataEventListener");

        geoQuery.addGeoQueryEventListener(new GeoQueryEventListener() {
            @Override
            public void onKeyEntered(String s, GeoPoint geoPoint) {
                map.put(s, geoPoint);
//                LogFileWriter.print(TAG, "onKeyEntered: \uD83D\uDD35 :: geoPoint found .... adding to hash map: " + map.size()
//                + " geoPoint: " + geoPoint.getLatitude() + " " + geoPoint.getLongitude() + "\n");
            }

            @Override
            public void onKeyExited(String s) {

            }

            @Override
            public void onKeyMoved(String s, GeoPoint geoPoint) {

            }

            @Override
            public void onGeoQueryReady() {
                LogFileWriter.print(TAG, "onGeoQueryReady:   ✅ - ready to deliver IDs for getting landmarks: " + map.size() + "\n");
                List<HashMap<String,String>> list = new ArrayList<>();
                for (String key: map.keySet()) {
                    HashMap<String,String> mapx = new HashMap<>();
                    mapx.put(key, G.toJson(map.get(key)));
                    list.add(mapx);
                }
                LogFileWriter.print(TAG, "onGeoQueryReady:   ✅ - returning " + list.size() + " geoPoints\n");
                listener.onLandmarkPointsFound(list);
            }

            @Override
            public void onGeoQueryError(Exception e) {
                Log.e(TAG, "‼️onGeoQueryError:  \uD83D\uDCCD  \uD83D\uDCCD  \uD83D\uDCCD Sir, Sir can I please have some more? ", e);
            }
        });
    }
    private static final Gson G = new GsonBuilder().setPrettyPrinting().create();


}


