package com.example.migrator2.api.google;

import java.io.Serializable;
import java.text.SimpleDateFormat;
import java.util.Locale;

/**
 * Created by aubreymalabie on 9/6/17.
 */

public class Properties implements Serializable{
    private String associationID, associationName, vehicleID, vehicleReg, beaconType, stringDate, date;
    private static final Locale LOCALE = Locale.getDefault();
    public static final SimpleDateFormat sdf = new SimpleDateFormat("EEE, dd MMMM yyyy HH:mm",LOCALE);

    public String getAssociationName() {
        return associationName;
    }

    public void setAssociationName(String associationName) {
        this.associationName = associationName;
    }

    public String getStringDate() {
        return stringDate;
    }

    public void setStringDate(String stringDate) {
        this.stringDate = stringDate;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getAssociationID() {
        return associationID;
    }

    public String getVehicleReg() {
        return vehicleReg;
    }

    public void setVehicleReg(String vehicleReg) {
        this.vehicleReg = vehicleReg;
    }

    public String getVehicleID() {
        return vehicleID;
    }

    public void setVehicleID(String vehicleID) {
        this.vehicleID = vehicleID;
    }

    public void setAssociationID(String associationID) {
        this.associationID = associationID;
    }

    public String getBeaconType() {
        return beaconType;
    }

    public void setBeaconType(String beaconType) {
        this.beaconType = beaconType;
    }
}
