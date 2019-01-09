package com.aftarobot.vehicle.util;

import com.google.firebase.firestore.GeoPoint;

import java.util.HashMap;
import java.util.List;

public interface LandmarkGeoPointListener {
    void onLandmarkPointsFound(List<HashMap<String,String>> geoPoints);
}
