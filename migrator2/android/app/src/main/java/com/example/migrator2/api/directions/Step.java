package com.example.migrator2.api.directions;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 9/18/16.
 */

public class Step implements Serializable {
    private Distance2 distance;

    public Distance2 getDistance() {
        return this.distance;
    }

    public void setDistance(Distance2 distance) {
        this.distance = distance;
    }

    private Duration2 duration;

    public Duration2 getDuration() {
        return this.duration;
    }

    public void setDuration(Duration2 duration) {
        this.duration = duration;
    }

    private EndLocation2 end_location;

    public EndLocation2 getEndLocation() {
        return this.end_location;
    }

    public void setEndLocation(EndLocation2 end_location) {
        this.end_location = end_location;
    }

    private String html_instructions;

    public String getHtmlInstructions() {
        return this.html_instructions;
    }

    public void setHtmlInstructions(String html_instructions) {
        this.html_instructions = html_instructions;
    }

    private Polyline polyline;

    public Polyline getPolyline() {
        return this.polyline;
    }

    public void setPolyline(Polyline polyline) {
        this.polyline = polyline;
    }

    private StartLocation2 start_location;

    public StartLocation2 getStartLocation() {
        return this.start_location;
    }

    public void setStartLocation(StartLocation2 start_location) {
        this.start_location = start_location;
    }

    private String travel_mode;

    public String getTravelMode() {
        return this.travel_mode;
    }

    public void setTravelMode(String travel_mode) {
        this.travel_mode = travel_mode;
    }

    private String maneuver;

    public String getManeuver() {
        return this.maneuver;
    }

    public void setManeuver(String maneuver) {
        this.maneuver = maneuver;
    }
}
