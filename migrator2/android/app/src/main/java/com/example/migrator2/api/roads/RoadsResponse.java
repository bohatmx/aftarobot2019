package com.example.migrator2.api.roads;

import java.util.ArrayList;

/**
 * Created by aubreymalabie on 9/18/16.
 */

public class RoadsResponse {
    private ArrayList<SnappedPoint> snappedPoints;

    public ArrayList<SnappedPoint> getSnappedPoints() {
        return this.snappedPoints;
    }

    public void setSnappedPoints(ArrayList<SnappedPoint> snappedPoints) {
        this.snappedPoints = snappedPoints;
    }
}
