package com.example.migrator2.api.directions;

import com.example.migrator2.api.distancematrix.Distance;
import com.example.migrator2.api.distancematrix.Duration;

import java.io.Serializable;
import java.util.ArrayList;

/**
 * Created by aubreymalabie on 9/18/16.
 */


public class Leg  implements Serializable{
    private Distance distance;
    private Duration duration;
    private String end_address;
    private EndLocation end_location;
    private String start_address;
    private StartLocation start_location;
    private ArrayList<Step> steps;
    private ArrayList<GeocodedWaypoint> via_waypoint;

    public Distance getDistance() {
        return this.distance;
    }

    public void setDistance(Distance distance) {
        this.distance = distance;
    }


    public Duration getDuration() {
        return this.duration;
    }

    public void setDuration(Duration duration) {
        this.duration = duration;
    }


    public String getEndAddress() {
        return this.end_address;
    }

    public void setEndAddress(String end_address) {
        this.end_address = end_address;
    }


    public EndLocation getEndLocation() {
        return this.end_location;
    }

    public void setEndLocation(EndLocation end_location) {
        this.end_location = end_location;
    }


    public String getStartAddress() {
        return this.start_address;
    }

    public void setStartAddress(String start_address) {
        this.start_address = start_address;
    }


    public StartLocation getStartLocation() {
        return this.start_location;
    }

    public void setStartLocation(StartLocation start_location) {
        this.start_location = start_location;
    }


    public ArrayList<Step> getSteps() {
        return this.steps;
    }

    public void setSteps(ArrayList<Step> steps) {
        this.steps = steps;
    }


    public ArrayList<GeocodedWaypoint> getViaWaypoint() {
        return this.via_waypoint;
    }

    public void setViaWaypoint(ArrayList<GeocodedWaypoint> via_waypoint) {
        this.via_waypoint = via_waypoint;
    }
}
