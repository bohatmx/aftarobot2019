package com.example.migrator2.api.directions;

import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.PolylineOptions;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by aubreymalabie on 9/18/16.
 */

public class OverviewPolyline implements Serializable {
    private String points;

    public String getPoints() {
        return this.points;
    }

    public void setPoints(String points) {
        this.points = points;
    }
    PolylineOptions polylineOptions;

    public PolylineOptions getPolylineOptions() {
        return polylineOptions;
    }

    public  PolylineOptions decodePoly() {

        List<LatLng> poly = new ArrayList<LatLng>();
        int index = 0, len = points.length();
        int lat = 0, lng = 0;

        while (index < len) {
            int b, shift = 0, result = 0;
            do {
                b = points.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lat += dlat;

            shift = 0;
            result = 0;
            do {
                b = points.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lng += dlng;

            LatLng p = new LatLng((((double) lat / 1E5)),
                    (((double) lng / 1E5)));
            poly.add(p);
        }

        polylineOptions = new PolylineOptions();

        for (LatLng latLng: poly) {
            polylineOptions.add(latLng);
        }
        polylineOptions.geodesic(true);
        polylineOptions.width(12);
        return polylineOptions;
    }
}

