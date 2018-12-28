package com.example.migrator2.api.google;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 6/11/16.
 */
public class EstimoteBeacon implements Serializable {
    private String beaconName;
    private String advertisedId;

    public String getBeaconName() {
        return beaconName;
    }

    public void setBeaconName(String beaconName) {
        this.beaconName = beaconName;
    }

    public String getAdvertisedId() {
        return advertisedId;
    }

    public void setAdvertisedId(String advertisedId) {
        this.advertisedId = advertisedId;
    }
}
