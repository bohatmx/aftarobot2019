package com.example.migrator2.api.directions;

import java.io.Serializable;
import java.util.ArrayList;

/**
 * Created by aubreymalabie on 9/18/16.
 */

public class Route implements Serializable {
    private Bounds bounds;
    private ArrayList<Leg> legs;
    private String copyrights;
    private String summary;
    private ArrayList<Object> warnings;
    private ArrayList<GeocodedWaypoint> waypoint_order;
    private OverviewPolyline overview_polyline;

    public Bounds getBounds() {
        return this.bounds;
    }

    public void setBounds(Bounds bounds) {
        this.bounds = bounds;
    }


    public String getCopyrights() {
        return this.copyrights;
    }

    public void setCopyrights(String copyrights) {
        this.copyrights = copyrights;
    }


    public ArrayList<Leg> getLegs() {
        return this.legs;
    }

    public void setLegs(ArrayList<Leg> legs) {
        this.legs = legs;
    }


    public OverviewPolyline getOverviewPolyline() {
        return this.overview_polyline;
    }

    public void setOverviewPolyline(OverviewPolyline overview_polyline) {
        this.overview_polyline = overview_polyline;
    }


    public String getSummary() {
        return this.summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }


    public ArrayList<Object> getWarnings() {
        return this.warnings;
    }

    public void setWarnings(ArrayList<Object> warnings) {
        this.warnings = warnings;
    }


    public ArrayList<GeocodedWaypoint> getWaypointOrder() {
        return this.waypoint_order;
    }

    public void setWaypointOrder(ArrayList<GeocodedWaypoint> waypoint_order) {
        this.waypoint_order = waypoint_order;
    }
}
