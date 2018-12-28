package com.example.migrator2.api.directions;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 9/18/16.
 */

public class Southwest implements Serializable {
    private double lat;
    private double lng;

    public double getLat() {
        return this.lat;
    }

    public void setLat(double lat) {
        this.lat = lat;
    }



    public double getLng() {
        return this.lng;
    }

    public void setLng(double lng) {
        this.lng = lng;
    }
}

