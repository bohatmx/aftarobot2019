package com.example.migrator2.api.directions;

import java.io.Serializable;
import java.util.ArrayList;

/**
 * Created by aubreymalabie on 9/18/16.
 */


public class DirectionsResponse implements Serializable {
    private ArrayList<GeocodedWaypoint> geocoded_waypoints;

    public ArrayList<GeocodedWaypoint> getGeocodedWaypoints() {
        return this.geocoded_waypoints;
    }

    public void setGeocodedWaypoints(ArrayList<GeocodedWaypoint> geocoded_waypoints) {
        this.geocoded_waypoints = geocoded_waypoints;
    }

    private ArrayList<Route> routes;

    public ArrayList<Route> getRoutes() {
        return this.routes;
    }

    public void setRoutes(ArrayList<Route> routes) {
        this.routes = routes;
    }

    private String status;

    public String getStatus() {
        return this.status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
