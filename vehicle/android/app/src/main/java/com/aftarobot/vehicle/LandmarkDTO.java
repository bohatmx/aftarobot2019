/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.aftarobot.vehicle;

import android.location.Location;
import android.location.LocationManager;

import com.google.firebase.database.Exclude;
import com.google.firebase.database.IgnoreExtraProperties;

import java.io.Serializable;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;


/**
 * @author Aubrey Malabie Esq.
 */
@IgnoreExtraProperties
public class LandmarkDTO implements Serializable, Comparable<LandmarkDTO> {
    public static final String TAG = LandmarkDTO.class.getSimpleName();

    private String landmarkID, cityID, associationID,
            routeID, countryID, provinceID, routeName, associationName;
    private int rankSequenceNumber;
    private double latitude, longitude, accuracy;
    public Long cacheDate;
    private UserDTO routeBuilder;
    private Boolean gpsScanned;

    private String landmarkName, status, cityName, stringDate;
    private Long date;
    @Exclude
    private double distanceFromMe;
    private MainRankDTO mainRank;
    private Boolean thisIsMainRank = Boolean.FALSE, virtualLandmark = Boolean.FALSE;
    private HashMap<String, PhotoDTO> photos;
    private HashMap<String, PlaceDTO> places;
    private static final Locale loc = Locale.getDefault();
    private static final SimpleDateFormat sdf = new SimpleDateFormat("EEEE dd MMMM yyyy HH:mm",loc);

    public Boolean getGpsScanned() {
        return gpsScanned;
    }

    public HashMap<String, PlaceDTO> getPlaces() {
        return places;
    }

    public void setPlaces(HashMap<String, PlaceDTO> places) {
        this.places = places;
    }

    public void setGpsScanned(Boolean gpsScanned) {
        this.gpsScanned = gpsScanned;
    }

    public String getAssociationName() {
        return associationName;
    }

    public void setAssociationName(String associationName) {
        this.associationName = associationName;
    }

    public double getAccuracy() {
        return accuracy;
    }

    public void setAccuracy(double accuracy) {
        this.accuracy = accuracy;
    }

    public UserDTO getRouteBuilder() {
        return routeBuilder;
    }

    public void setRouteBuilder(UserDTO routeBuilder) {
        this.routeBuilder = routeBuilder;
    }

    public String getStringDate() {
        return stringDate;
    }

    public void setStringDate(String stringDate) {
        this.stringDate = stringDate;
    }

    public Boolean getVirtualLandmark() {
        return virtualLandmark;
    }

    public void setVirtualLandmark(Boolean virtualLandmark) {
        this.virtualLandmark = virtualLandmark;
    }

    public Boolean getThisIsMainRank() {
        return thisIsMainRank;
    }

    public void setThisIsMainRank(Boolean thisIsMainRank) {
        this.thisIsMainRank = thisIsMainRank;
    }

    public MainRankDTO getMainRank() {
        return mainRank;
    }

    public void setMainRank(MainRankDTO mainRank) {
        this.mainRank = mainRank;
    }

    public String getAssociationID() {
        return associationID;
    }

    public void setAssociationID(String associationID) {
        this.associationID = associationID;
    }

    private HashMap<String, TripDTO> trips;

    public LandmarkDTO() {
        date = new Date().getTime();
        stringDate = sdf.format(date);
    }

    public HashMap<String, PhotoDTO> getPhotos() {
        return photos;
    }

    public void setPhotos(HashMap<String, PhotoDTO> photos) {
        this.photos = photos;
    }

    public void calculateDistanceFromMe(Location loc) {
        if (loc == null) {
            return;
        }
        Location location = new Location(LocationManager.GPS_PROVIDER);
        if (latitude == 0 && longitude == 0) {
            distanceFromMe = -1.0;
            return;
        }
        location.setLatitude(latitude);
        location.setLongitude(longitude);
        distanceFromMe = Double.parseDouble(String.valueOf(location.distanceTo(loc)));
    }

    @Exclude
    public double getDistanceFromMe() {
        return distanceFromMe;
    }

    public HashMap<String, TripDTO> getTrips() {
        return trips;
    }

    public void setTrips(HashMap<String, TripDTO> trips) {
        this.trips = trips;
    }

    public String getRouteName() {
        return routeName;
    }

    public void setRouteName(String routeName) {
        this.routeName = routeName;
    }

    public String getProvinceID() {
        return provinceID;
    }

    public void setProvinceID(String provinceID) {
        this.provinceID = provinceID;
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

    Boolean sortByRankSequence = false;
    @Exclude
    Boolean sortByName = false;
    @Exclude
    Boolean sortByDistance = false;

    public void setSortByRankSequence(Boolean sortByRankSequence) {
        this.sortByRankSequence = sortByRankSequence;
    }

    public void setSortByDistance(Boolean sortByDistance) {
        this.sortByDistance = sortByDistance;
    }

    public void setSortByName(Boolean sortByName) {
        this.sortByName = sortByName;
    }

    public void setCacheDate(Long cacheDate) {
        this.cacheDate = cacheDate;
    }

    @Override
    public int compareTo(LandmarkDTO another) {
        if (sortByDistance) {
            if (this.distanceFromMe > another.distanceFromMe) {
                return 1;
            }
            if (this.distanceFromMe < another.distanceFromMe) {
                return -1;
            }
        }
        if (sortByRankSequence) {
            if (this.rankSequenceNumber > another.rankSequenceNumber) {
                return 1;
            }
            if (this.rankSequenceNumber < another.rankSequenceNumber) {
                return -1;
            }

        }
        if (sortByName) {
            return this.landmarkName.compareTo(another.landmarkName);
        }
        return this.landmarkName.compareTo(another.landmarkName);

    }
}
