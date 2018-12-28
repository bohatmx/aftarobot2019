package com.example.migrator2.api.roads;

/**
 * Created by aubreymalabie on 9/18/16.
 */


public class SnappedPoint {
    private Location location;

    public Location getLocation() {
        return this.location;
    }

    public void setLocation(Location location) {
        this.location = location;
    }

    private int originalIndex;

    public int getOriginalIndex() {
        return this.originalIndex;
    }

    public void setOriginalIndex(int originalIndex) {
        this.originalIndex = originalIndex;
    }

    private String placeId;

    public String getPlaceId() {
        return this.placeId;
    }

    public void setPlaceId(String placeId) {
        this.placeId = placeId;
    }
}
