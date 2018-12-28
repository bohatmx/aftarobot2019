package com.example.migrator2.api.directions;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 9/18/16.
 */

public class Bounds implements Serializable {
    private Northeast northeast;
    private Southwest southwest;

    public Northeast getNortheast() {
        return this.northeast;
    }

    public void setNortheast(Northeast northeast) {
        this.northeast = northeast;
    }



    public Southwest getSouthwest() {
        return this.southwest;
    }

    public void setSouthwest(Southwest southwest) {
        this.southwest = southwest;
    }
}

