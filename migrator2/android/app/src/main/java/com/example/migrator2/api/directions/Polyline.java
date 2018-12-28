package com.example.migrator2.api.directions;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 9/18/16.
 */


public class Polyline implements Serializable {
    private String points;

    public String getPoints() {
        return this.points;
    }

    public void setPoints(String points) {
        this.points = points;
    }
}


