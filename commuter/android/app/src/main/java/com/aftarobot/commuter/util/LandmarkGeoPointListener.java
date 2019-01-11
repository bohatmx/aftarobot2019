package com.aftarobot.commuter.util;

import java.util.HashMap;
import java.util.List;

public interface LandmarkGeoPointListener {
    void onLandmarkPointsFound(List<HashMap<String, String>> geoPoints);
}
