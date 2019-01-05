package com.aftarobot.vehicle;

import android.annotation.SuppressLint;
import android.util.Log;

import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.EventListener;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.GeoPoint;
import com.google.firebase.firestore.QuerySnapshot;

import org.imperiumlabs.geofirestore.GeoFirestore;
import org.imperiumlabs.geofirestore.GeoQuery;
import org.imperiumlabs.geofirestore.GeoQueryDataEventListener;
import org.imperiumlabs.geofirestore.GeoQueryEventListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import javax.annotation.Nullable;

public class GeoPointHelper {
    static FirebaseFirestore fs = FirebaseFirestore.getInstance();
   static int count = 0;

   //todo - this code belongs in the migrator/routebuilder apps - not here
    static void setQueryLocations(List<LandmarkDTO> marks) {
        CollectionReference geoQueryLocationsRef = fs.collection("geoQueryLocations");
        final GeoFirestore geoFirestore = new GeoFirestore(geoQueryLocationsRef);

        for(final LandmarkDTO landmark: marks) {
            String documentID = landmark.getLandmarkID();
            geoFirestore.setLocation(documentID, new GeoPoint(landmark.getLatitude(), landmark.getLongitude()), new GeoFirestore.CompletionListener() {
                @Override
                public void onComplete(Exception exception) {
                    if (exception == null) {
                        count++;
                        Log.d(TAG,"✅ Location saved for #" + count + " :: " + landmark.getLandmarkName() + " on server successfully!");
                    } else {
                        Log.e(TAG, "onComplete:  ⚠️  ⚠️  ⚠️ WE HAVE A PROBLEM, Senor!" );
                    }
                }
            });
        }
    }
    static void findLandmarksWithin(final double latitude, final double longitude,
                                    final double radius, final GeoPointListener listener) {
        CollectionReference geoFirestoreRef = fs.collection("landmarks");
        CollectionReference newGeoFirestoreRef = fs.collection("newLandmarks");
        final GeoFirestore geoFirestore = new GeoFirestore(geoFirestoreRef);
        readDocuments(latitude, longitude, radius, listener, geoFirestore);


    }

    private static void readDocuments(double latitude, double longitude, double radius, final GeoPointListener listener, GeoFirestore geoFirestore) {
        Log.d(TAG, "\n\n---- queryLocationsWithin: \uD83D\uDCCD \uD83D\uDCCD starting geo search ...............");


        final List<LandmarkDTO> landmarks = new ArrayList<>();
        GeoQuery geoQuery = geoFirestore.queryAtLocation(new GeoPoint(latitude, longitude), radius);
        Log.d(TAG, "\uD83D\uDCCD \uD83D\uDCCD findLandmarksWithin: .......... adding addGeoQueryDataEventListener");
        geoQuery.addGeoQueryDataEventListener(new GeoQueryDataEventListener() {
            @Override
            public void onDocumentEntered(DocumentSnapshot documentSnapshot, GeoPoint location) {

                LandmarkDTO landmark = documentSnapshot.toObject(LandmarkDTO.class);
                landmarks.add(landmark);
                Log.d(TAG, "onDocumentEntered: landmark found .... adding to list: " + landmarks.size());
            }

            @Override
            public void onDocumentExited(DocumentSnapshot documentSnapshot) {
                // ...
            }

            @Override
            public void onDocumentMoved(DocumentSnapshot documentSnapshot, GeoPoint location) {
                // ...
            }

            @Override
            public void onDocumentChanged(DocumentSnapshot documentSnapshot, GeoPoint location) {
                // ...
            }

            @Override
            public void onGeoQueryReady() {
                Log.d(TAG, "onGeoQueryReady:   ✅ - ready to deliver " + landmarks.size());
                listener.onLandmarksFound(landmarks);
            }

            @Override
            public void onGeoQueryError(Exception exception) {
                Log.d(TAG, "\uD83C\uDFBE \uD83C\uDFBE \uD83C\uDFBE  onGeoQueryError: " + exception.getMessage());
            }
        });
    }

    private static final String TAG = GeoPointHelper.class.getSimpleName();

}


