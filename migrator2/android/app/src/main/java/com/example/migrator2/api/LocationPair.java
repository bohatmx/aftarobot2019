package com.example.migrator2.api;

import com.google.android.gms.maps.model.LatLng;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class LocationPair {
    static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private double originLatitude, originLongitude;
    private double destinationLatitude, destinationLongitude;

    public LocationPair(double originLatitude, double originLongitude) {
        this.originLatitude = originLatitude;
        this.originLongitude = originLongitude;
    }

    public LatLng getOrigin() {
        LatLng m = new LatLng(originLatitude, originLongitude);
        return m;
    }
    public LatLng getDestination() {
        return new LatLng(destinationLatitude, destinationLongitude);
    }
    public String toJson() {
        return GSON.toJson(this);
    }

    public double getDestinationLatitude() {
        return destinationLatitude;
    }

    public void setDestinationLatitude(double destinationLatitude) {
        this.destinationLatitude = destinationLatitude;
    }

    public double getDestinationLongitude() {
        return destinationLongitude;
    }

    public void setDestinationLongitude(double destinationLongitude) {
        this.destinationLongitude = destinationLongitude;
    }

    public double getOriginLatitude() {
        return originLatitude;
    }

    public void setOriginLatitude(double originLatitude) {
        this.originLatitude = originLatitude;
    }

    public double getOriginLongitude() {
        return originLongitude;
    }

    public void setOriginLongitude(double originLongitude) {
        this.originLongitude = originLongitude;
    }
}
