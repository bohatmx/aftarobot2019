package com.aftarobot.commuter.util;

import com.google.firebase.firestore.GeoPoint;

import java.util.HashMap;

public interface VehicleGeoPointListener {
    void onGeoPointsFound(HashMap<String, GeoPoint> map);
}
