/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.aftarobot.vehicle.util;

import java.io.Serializable;

/**
 * @author Aubrey Malabie, Esq.
 */
public class VehicleDTO implements Serializable, Comparable<VehicleDTO> {

    private String vehicleID, ownerID,
            associationID, countryID, ownerName, associationName;
    private VehicleTypeDTO vehicleType;
    private String year, stringDate,path,
            vehicleReg;
    private Boolean selected;

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public String getAssociationName() {
        return associationName;
    }

    public void setAssociationName(String associationName) {
        this.associationName = associationName;
    }
    public Boolean getSelected() {
        return selected;
    }

    public void setSelected(Boolean selected) {
        this.selected = selected;
    }

    public String getStringDate() {
        return stringDate;
    }

    public void setStringDate(String stringDate) {
        this.stringDate = stringDate;
    }

    public String getVehicleID() {
        return vehicleID;
    }

    public void setVehicleID(String vehicleID) {
        this.vehicleID = vehicleID;
    }

    public String getOwnerID() {
        return ownerID;
    }

    public void setOwnerID(String ownerID) {
        this.ownerID = ownerID;
    }

    public String getAssociationID() {
        return associationID;
    }

    public void setAssociationID(String associationID) {
        this.associationID = associationID;
    }

    public String getCountryID() {
        return countryID;
    }

    public void setCountryID(String countryID) {
        this.countryID = countryID;
    }

    public String getOwnerName() {
        return ownerName;
    }

    public void setOwnerName(String ownerName) {
        this.ownerName = ownerName;
    }


    public VehicleTypeDTO getVehicleType() {
        return vehicleType;
    }

    public void setVehicleType(VehicleTypeDTO vehicleType) {
        this.vehicleType = vehicleType;
    }



    public String getYear() {
        return year;
    }

    public void setYear(String year) {
        this.year = year;
    }


    public String getVehicleReg() {
        return vehicleReg;
    }

    public void setVehicleReg(String vehicleReg) {
        this.vehicleReg = vehicleReg;
    }
    @Override
    public int compareTo(VehicleDTO o) {
        if (this.vehicleReg == null || o.vehicleReg == null) {
            return 0;
        }
        return this.vehicleReg.compareTo(o.vehicleReg);
    }

}
