package com.aftarobot.vehicle;

import android.annotation.SuppressLint;
import android.util.Log;

import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.EventListener;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.GeoPoint;

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

    static void findLandmarksWithin(double latitude, double longitude, double radius, final GeoPointListener listener) {

        Log.d(TAG, "queryLocationsWithin: \uD83D\uDCCD \uD83D\uDCCD starting geo search ...............");
        CollectionReference geoFirestoreRef = fs.collection("landmarks");

        GeoFirestore geoFirestore = new GeoFirestore(geoFirestoreRef);
        final List<LandmarkDTO> landmarks = new ArrayList<>();
        GeoQuery geoQuery = geoFirestore.queryAtLocation(new GeoPoint(latitude, longitude), radius);
        geoQuery.addGeoQueryDataEventListener(new GeoQueryDataEventListener() {
            @Override
            public void onDocumentEntered(DocumentSnapshot documentSnapshot, GeoPoint location) {
                LandmarkDTO landmark = documentSnapshot.toObject(LandmarkDTO.class);
                landmarks.add(landmark);
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
                listener.onLandmarksFound(landmarks);
            }

            @Override
            public void onGeoQueryError(Exception exception) {
                // ...
            }
        });
    }

    private static final String TAG = GeoPointHelper.class.getSimpleName();

}


