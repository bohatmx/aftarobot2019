package com.example.migrator2.api.distancematrix;

/**
 * Created by aubreymalabie on 9/18/16.
 */

public class Element
{
    private String status;

    public String getStatus() { return this.status; }

    public void setStatus(String status) { this.status = status; }

    private Duration duration;

    public Duration getDuration() { return this.duration; }

    public void setDuration(Duration duration) { this.duration = duration; }

    private Distance distance;

    public Distance getDistance() { return this.distance; }

    public void setDistance(Distance distance) { this.distance = distance; }
}
