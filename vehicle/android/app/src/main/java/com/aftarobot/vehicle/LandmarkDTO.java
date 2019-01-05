/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.aftarobot.vehicle;

import java.io.Serializable;



/**
 * @author Aubrey Malabie Esq.
 */
public class LandmarkDTO implements Serializable{
    public static final String TAG = LandmarkDTO.class.getSimpleName();

    private String landmarkID, cityID, associationID,
            routeID, countryID, routeName, associationName;
    private int rankSequenceNumber;
    private double latitude, longitude;

    private String landmarkName, status, cityName, stringDate;
    private Long date;
    private Boolean thisIsMainRank = Boolean.FALSE;

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


    public Boolean getThisIsMainRank() {
        return thisIsMainRank;
    }

    public void setThisIsMainRank(Boolean thisIsMainRank) {
        this.thisIsMainRank = thisIsMainRank;
    }


    public String getAssociationID() {
        return associationID;
    }

    public void setAssociationID(String associationID) {
        this.associationID = associationID;
    }

    public String getRouteName() {
        return routeName;
    }

    public void setRouteName(String routeName) {
        this.routeName = routeName;
    }

    public String getCountryID() {
        return countryID;
    }

    public void setCountryID(String countryID) {
        this.countryID = countryID;
    }

    public String getCityID() {
        return cityID;
    }

    public void setCityID(String cityID) {
        this.cityID = cityID;
    }

    public String getLandmarkID() {
        return landmarkID;
    }

    public void setLandmarkID(String landmarkID) {
        this.landmarkID = landmarkID;
    }

    public int getRankSequenceNumber() {
        return rankSequenceNumber;
    }

    public void setRankSequenceNumber(int rankSequenceNumber) {
        this.rankSequenceNumber = rankSequenceNumber;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }

    public String getLandmarkName() {
        return landmarkName;
    }

    public void setLandmarkName(String landmarkName) {
        this.landmarkName = landmarkName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public long getDate() {
        return date;
    }

    public void setDate(long date) {
        this.date = date;
    }

    public String getRouteID() {
        return routeID;
    }

    public void setRouteID(String routeID) {
        this.routeID = routeID;
    }

    public String getCityName() {
        return cityName;
    }

    public void setCityName(String cityName) {
        this.cityName = cityName;
    }


}
