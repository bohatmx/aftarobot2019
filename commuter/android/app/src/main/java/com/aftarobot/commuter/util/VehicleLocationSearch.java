package com.aftarobot.commuter.util;

import android.support.annotation.NonNull;
import android.util.Log;

import com.aftarobot.commuter.log.LogFileWriter;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.DocumentSnapshot;
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

public class VehicleLocationSearch {

    private static VehicleLocationListener vehicleLocationListener;
    private static List<VehicleLocation> vehicleLocations = new ArrayList<>();


    public static void findVehicleLocations(int withinMinutes,
                                     double latitude, double longitude, double radius,
                                     final VehicleLocationListener listener) {
        LogFileWriter.print(TAG, "\n findVehicleLocations: *** vehicles recorded since  ℹ️ : " + withinMinutes + " ago ...");
        vehicleLocationListener = listener;
        vehicleLocations.clear();

        String key = "" + (new Date().getTime() - (withinMinutes * 60 * 1000));
        findVehiclesWithinRadius(latitude, longitude, radius, key);

    }
    private static void findVehiclesWithinRadius(final double latitude,
                                                 final double longitude,
                                                 final double radius, final String key) {

        LogFileWriter.print(TAG, "findVehiclesWithinRadius: ***  ℹ️ setting up GeoFirestore for geo vehicle query  ℹ️");
        final FirebaseFirestore fs = FirebaseFirestore.getInstance();

        CollectionReference geoFirestoreRef = fs.collection("geoVehicleLocations");
        final GeoFirestore geoFirestore = new GeoFirestore(geoFirestoreRef);

        searchVehicleGeoPoints(latitude, longitude, radius, geoFirestore, new VehicleGeoPointListener() {
            @Override
            public void onGeoPointsFound(final HashMap<String, GeoPoint> map) {
                final HashMap<String, VehicleLocation> hashMap = new HashMap<>();
                for (final String pointKey: map.keySet()) {
//                    LogFileWriter.print(TAG, "onGeoPointsFound: pointKey: look for multiple @ for splitting: ".concat(pointKey));
                    String[] strings = pointKey.split("@");
                    final String time = strings[0];
                    String associations = strings[1];
                    String assocID = strings[2];
                    String vehicles = strings[3];
                    String vehicleID = strings[4];
                    String vehiclePath = associations + "/" + assocID + "/" + vehicles + "/" + vehicleID;
                    String mDate = new Date(Long.parseLong(time)).toString();
//                    LogFileWriter.print(TAG, "onGeoPointsFound: found vehicle; check for time limit:  ⚠️⚠️️ vehiclePath: ".concat(vehiclePath)
//                    .concat(" recorded at: ".concat(mDate)));
                    if (time.compareTo(key) > 0) {
                        //todo - filter for duplicate vehicles
                        VehicleLocation vehicleLocation = new VehicleLocation();
                        GeoPoint point = map.get(pointKey);
                        vehicleLocation.setLatitude(point.getLatitude());
                        vehicleLocation.setLongitude(point.getLongitude());
                        vehicleLocation.setDate(new Date(Long.parseLong(time)).toString());
                        vehicleLocation.setTimestamp(new Date(Long.parseLong(time)).getTime());
                        VehicleDTO vehicle = new VehicleDTO();
                        vehicle.setPath(vehiclePath);
                        vehicleLocation.setVehicle(vehicle);
                        hashMap.put(vehicleID, vehicleLocation);
                        LogFileWriter.print(TAG, G.toJson(vehicleLocation));
                        LogFileWriter.print(TAG, "searchVehicleGeoPoints: \uD83D\uDD35 found vehicle within time limit. path: " + vehiclePath);
                    }
                }

                LogFileWriter.print(TAG, "searchVehicleGeoPoints:  ⚠️⚠️ ️found vehicles within time limit: "
                        + hashMap.size() +" vehicles  ... ");
                for (final String vehicleID: hashMap.keySet()) {
                   final VehicleLocation vehicleLocation = hashMap.get(vehicleID);
                    fs.document(vehicleLocation.getVehicle().getPath()).get().addOnSuccessListener(new OnSuccessListener<DocumentSnapshot>() {
                        @Override
                        public void onSuccess(DocumentSnapshot documentSnapshot) {
                            if (documentSnapshot.exists()) {
                                VehicleDTO v = documentSnapshot.toObject(VehicleDTO.class);
                                vehicleLocation.setVehicle(v);
                                vehicleLocations.add(vehicleLocation);
                            }
                        }
                    }).addOnFailureListener(new OnFailureListener() {
                        @Override
                        public void onFailure(@NonNull Exception e) {
                            Log.e(TAG, "‼️‼️onFailure: ",e );
                        }
                    });
                }

                LogFileWriter.print(TAG, "searchVehicleGeoPoints::: \uD83D\uDD35  \uD83D\uDD35 vehicles found around us: " + vehicleLocations.size());
                vehicleLocationListener.onVehiclesFound(vehicleLocations);
            }
        });

    }

    private static void searchVehicleGeoPoints(double latitude,
                                               double longitude,
                                               double radius,
                                               GeoFirestore geoFirestore,
                                               final VehicleGeoPointListener listener) {
        LogFileWriter.print(TAG, "\n\n---- ****** searchVehicleGeoPoints: \uD83D\uDCCD \uD83D\uDCCD starting geo search ...............");

        final HashMap<String, GeoPoint> map = new HashMap<>();
        GeoQuery geoQuery = geoFirestore.queryAtLocation(new GeoPoint(latitude, longitude), radius);
        LogFileWriter.print(TAG, "\uD83D\uDCCD \uD83D\uDCCD searchVehicleGeoPoints radius: "+radius+" km. ... adding addGeoQueryDataEventListener");

        geoQuery.addGeoQueryEventListener(new GeoQueryEventListener() {
            @Override
            public void onKeyEntered(String s, GeoPoint geoPoint) {
                map.put(s, geoPoint);
//                LogFileWriter.print(TAG, "onKeyEntered: \uD83D\uDD35 :: vehicle found .... adding to hash map: " + map.size()
//                + " key: "+s+" - geoPoint: " + new Gson().toJson(geoPoint));
            }

            @Override
            public void onKeyExited(String s) {

            }

            @Override
            public void onKeyMoved(String s, GeoPoint geoPoint) {

            }

            @Override
            public void onGeoQueryReady() {
                LogFileWriter.print(TAG, "onGeoQueryReady:   ✅ - returning " + map.size() + " vehicle points located. will check time");
                listener.onGeoPointsFound(map);
            }

            @Override
            public void onGeoQueryError(Exception e) {
                LogFileWriter.print(TAG, "‼️‼️onGeoQueryError:  \uD83D\uDCCD  \uD83D\uDCCD  \uD83D\uDCCD Sir, Sir can I please have some more? ");
            }
        });
    }
    public static final Gson G = new GsonBuilder().setPrettyPrinting().create();

    private static final String TAG = VehicleLocationSearch.class.getSimpleName();

}


