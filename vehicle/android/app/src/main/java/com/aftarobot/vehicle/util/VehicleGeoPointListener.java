package com.aftarobot.vehicle.util;

import com.google.firebase.firestore.GeoPoint;

import java.util.HashMap;
import java.util.List;

public interface VehicleGeoPointListener {
    void onGeoPointsFound(HashMap<String, GeoPoint> map);
}
