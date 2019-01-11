package com.aftarobot.commuter.util;

import android.support.annotation.NonNull;

import com.google.gson.Gson;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 9/10/16.
 */

public class VehicleTypeDTO implements Serializable, Comparable<VehicleTypeDTO> {

    public VehicleTypeDTO() {
    }

    public VehicleTypeDTO(String make, String model, int capacity) {
        this.capacity = capacity;
        this.make = make;
        this.model = model;
    }

    private int capacity;
    private String vehicleTypeID, make, model, countryID;

    public String getVehicleTypeID() {
        return vehicleTypeID;
    }

    public void setVehicleTypeID(String vehicleTypeID) {
        this.vehicleTypeID = vehicleTypeID;
    }

    public String getCountryID() {
        return countryID;
    }

    public void setCountryID(String countryID) {
        this.countryID = countryID;
    }

    public int getCapacity() {
        return capacity;
    }

    public void setCapacity(int capacity) {
        this.capacity = capacity;
    }

    public String getMake() {
        return make;
    }

    public void setMake(String make) {
        this.make = make;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    @Override
    public int compareTo(@NonNull VehicleTypeDTO o) {
        if (this.make == null || this.model == null) {
            return 0;
        }
        if (o.make == null || o.model == null) {
            return 0;
        }
        String m1 = this.make.concat(" ").concat(this.getModel());
        String m2 = o.make.concat(" ").concat(o.getModel());
        return m1.compareTo(m2);
    }

    static final Gson GSON = new Gson();
}
