import 'package:aftarobotlibrary/data/mainrankdto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';

/*
####### Generated by JavaToDart Wed Dec 19 22:12:26 SAST 2018
####### rigged up by AM Esq.
*/

class LandmarkDTO {
  String TAG;
  String landmarkID;
  String cityID;
  String associationID;
  String routeID;
  String countryID;
  String provinceID;
  String routeName;
  String associationName;
  int rankSequenceNumber;
  double latitude;
  double longitude;
  double accuracy;
  int cacheDate;
  UserDTO user;
  bool gpsScanned;
  String landmarkName;
  String status;
  String cityName;
  String stringDate;
  int date;
  double distanceFromMe;
  MainRankDTO mainRank;
  bool thisIsMainRank;
  bool virtualLandmark;
  bool sortByRankSequence;
  bool sortByName;
  bool sortByDistance;
  String path;

  LandmarkDTO({
    this.landmarkID,
    this.cityID,
    this.associationID,
    this.routeID,
    this.countryID,
    this.provinceID,
    this.routeName,
    this.associationName,
    this.rankSequenceNumber,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.cacheDate,
    this.gpsScanned,
    this.landmarkName,
    this.status,
    this.cityName,
    this.stringDate,
    this.date,
    this.distanceFromMe,
    this.mainRank,
    this.thisIsMainRank,
    this.virtualLandmark,
    this.sortByRankSequence,
    this.sortByName,
    this.sortByDistance,
  });

  LandmarkDTO.fromJson(Map data) {
    this.landmarkID = data['landmarkID'];
    this.cityID = data['cityID'];
    this.associationID = data['associationID'];
    this.routeID = data['routeID'];
    this.countryID = data['countryID'];
    this.provinceID = data['provinceID'];
    this.routeName = data['routeName'];
    this.associationName = data['associationName'];
    this.rankSequenceNumber = data['rankSequenceNumber'];

    if (data['accuracy'] != null) {
      if (data['accuracy'] is double) {
        this.accuracy = data['accuracy'];
      } else {
        this.accuracy = double.parse(data['accuracy'].toString());
      }
    }
    if (data['latitude'] != null) {
      if (data['latitude'] is double) {
        this.latitude = data['latitude'];
      } else {
        this.latitude = double.parse(data['latitude'].toString());
      }
    }
    if (data['longitude'] != null) {
      if (data['longitude'] is double) {
        this.longitude = data['longitude'];
      } else {
        this.longitude = double.parse(data['longitude'].toString());
      }
    }
    this.cacheDate = data['cacheDate'];
    this.gpsScanned = data['gpsScanned'];
    this.landmarkName = data['landmarkName'];
    this.status = data['status'];
    this.cityName = data['cityName'];
    this.stringDate = data['stringDate'];
    this.date = data['date'];

    if (data['mainRank'] != null) {
      this.mainRank = MainRankDTO.fromJson(data['mainRank']);
    }
    this.thisIsMainRank = data['thisIsMainRank'];
    this.virtualLandmark = data['virtualLandmark'];
    this.sortByRankSequence = data['sortByRankSequence'];
    this.sortByName = data['sortByName'];
    this.sortByDistance = data['sortByDistance'];
    this.path = data['path'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> mRank;
    if (mainRank != null) {
      mRank = mainRank.toJson();
    }
    Map<String, dynamic> map = {
      'landmarkID': landmarkID,
      'cityID': cityID,
      'associationID': associationID,
      'routeID': routeID,
      'countryID': countryID,
      'provinceID': provinceID,
      'routeName': routeName,
      'associationName': associationName,
      'rankSequenceNumber': rankSequenceNumber,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'cacheDate': cacheDate,
      'gpsScanned': gpsScanned,
      'landmarkName': landmarkName,
      'status': status,
      'cityName': cityName,
      'stringDate': stringDate,
      'date': date,
      'distanceFromMe': distanceFromMe,
      'mainRank': mRank,
      'thisIsMainRank': thisIsMainRank,
      'virtualLandmark': virtualLandmark,
      'sortByRankSequence': sortByRankSequence,
      'sortByName': sortByName,
      'sortByDistance': sortByDistance,
      'path': path,
    };
    return map;
  }
}
