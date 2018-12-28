package com.example.migrator2.api.directions;

import java.io.Serializable;
import java.util.ArrayList;

/**
 * Created by aubreymalabie on 9/18/16.
 */


public class GeocodedWaypoint implements Serializable {
    private String geocoder_status;
    private String place_id;
    private ArrayList<String> types;
    private Boolean partial_match;

    public String getGeocoderStatus() {
        return this.geocoder_status;
    }

    public void setGeocoderStatus(String geocoder_status) {
        this.geocoder_status = geocoder_status;
    }



    public String getPlaceId() {
        return this.place_id;
    }

    public void setPlaceId(String place_id) {
        this.place_id = place_id;
    }



    public ArrayList<String> getTypes() {
        return this.types;
    }

    public void setTypes(ArrayList<String> types) {
        this.types = types;
    }



    public Boolean getPartialMatch() {
        return this.partial_match;
    }

    public void setPartialMatch(Boolean partial_match) {
        this.partial_match = partial_match;
    }
}

