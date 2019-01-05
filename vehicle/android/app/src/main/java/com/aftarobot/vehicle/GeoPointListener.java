package com.aftarobot.vehicle;

import com.google.firebase.firestore.GeoPoint;

import java.util.HashMap;
import java.util.List;

public interface GeoPointListener {
    void onLandmarksFound(List<LandmarkDTO> landmarks);
}
