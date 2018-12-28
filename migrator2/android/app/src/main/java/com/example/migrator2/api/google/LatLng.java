package com.example.migrator2.api.google;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 6/11/16.
 */
public class LatLng  implements Serializable
{
    private double latitude;

    public double getLatitude() { return this.latitude; }

    public void setLatitude(double latitude) { this.latitude = latitude; }

    private double longitude;

    public double getLongitude() { return this.longitude; }

    public void setLongitude(double longitude) { this.longitude = longitude; }
}
