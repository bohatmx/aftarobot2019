package com.aftarobot.commuter.util;

public class VehicleLocation {
    private VehicleDTO vehicle;
    private long timestamp;
    private String date;
    private double latitude, longitude;

    public VehicleLocation() {
    }

    public VehicleLocation(VehicleDTO vehicle, long timestamp, String date, double latitude, double longitude) {
        this.vehicle = vehicle;
        this.timestamp = timestamp;
        this.date = date;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public VehicleDTO getVehicle() {
        return vehicle;
    }

    public void setVehicle(VehicleDTO vehicle) {
        this.vehicle = vehicle;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }
}
